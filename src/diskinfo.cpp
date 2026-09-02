#include "diskinfo.h"

#include <QFile>
#include <QDir>
#include <QRegularExpression>

DiskInfo::DiskInfo(QObject *parent) : QObject(parent)
{
	// Pre-fill graph history arrays with zeroes so the UI doesn't jump on first paint
	for (int i = 0; i < MAX_HISTORY_POINTS; ++i) {
		m_activeTimeHistory.append(0.0);
		m_readSpeedHistory.append(0.0);
		m_writeSpeedHistory.append(0.0);
	}

	detectPrimaryDisk();
	readStaticInfo();

	m_timeTracker.start();

	// Setup polling timer (1 second interval), self-driven like MemoryInfo/WifiInfo
	m_updateTimer = new QTimer(this);
	connect(m_updateTimer, &QTimer::timeout, this, &DiskInfo::updateDiskStats);
	m_updateTimer->start(1000);

	updateDiskStats();
}

void DiskInfo::detectPrimaryDisk()
{
    QString rootDevice = rootMountDevice();
    QString base = baseDeviceName(rootDevice);

    QDir blockDir("/sys/block");
    const QStringList allDevices = blockDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    QStringList realDevices;
    for (const QString &dev : allDevices) {
        // ADDED "dm-" to skip Device Mapper volumes
        if (dev.startsWith("loop") || dev.startsWith("ram") || dev.startsWith("zram") || dev.startsWith("dm-"))
            continue;
        realDevices.append(dev);
    }

    if (!base.isEmpty() && realDevices.contains(base)) {
        // Confirmed: this device is exactly where "/" is mounted.
        m_device = base;
        m_isSystemDisk = true;
        return;
    }

    // Explicitly prefer standard physical disks in mobile/embedded environments
    const QStringList preferredDisks = {"sda", "mmcblk0", "nvme0n1"};
    for (const QString &pref : preferredDisks) {
        if (realDevices.contains(pref)) {
            m_device = pref;
            m_isSystemDisk = true;
            return;
        }
    }

    // Standard fallback
    if (!realDevices.isEmpty()) {
        m_device = realDevices.first();
        m_isSystemDisk = (realDevices.size() == 1);
    }
}

QString DiskInfo::rootMountDevice() const
{
	QFile f("/proc/mounts");
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
		return QString();

	// procfs reports size() == 0, which makes atEnd() true immediately;
	// read everything up front instead of looping on atEnd().
	const QStringList lines = QString::fromUtf8(f.readAll()).split('\n');
	for (const QString &line : lines) {
		const QStringList parts = line.split(' ', Qt::SkipEmptyParts);
		if (parts.size() >= 2 && parts[1] == "/")
			return parts[0];
	}
	return QString();
}

QString DiskInfo::baseDeviceName(const QString &devicePath) const
{
	QString name = devicePath;
	if (name.startsWith("/dev/"))
		name = name.mid(5);

	// mmcblkNpM / nvmeXnYpZ -> strip the "pM" partition suffix
	static const QRegularExpression mmcNvme("^(mmcblk\\d+|nvme\\d+n\\d+)p\\d+$");
	QRegularExpressionMatch match = mmcNvme.match(name);
	if (match.hasMatch())
		return match.captured(1);

	// sdaN / vdaN / hdaN -> strip the trailing partition digits
	static const QRegularExpression simple("^([a-zA-Z]+)\\d+$");
	match = simple.match(name);
	if (match.hasMatch())
		return match.captured(1);

	return name; // Already a base device (or an unrecognized/synthetic name)
}

void DiskInfo::readStaticInfo()
{
	if (m_device.isEmpty())
		return;

	QString base = "/sys/block/" + m_device;

	// Model / product name -- path differs by bus type (SCSI/SATA/NVMe vs MMC)
	const QStringList modelPaths = {
		base + "/device/model", // SCSI / SATA / NVMe
		base + "/device/name",  // MMC / eMMC / UFS-over-MMC
	};
	for (const QString &path : modelPaths) {
		QFile modelFile(path);
		if (modelFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
			QString value = QString::fromUtf8(modelFile.readAll()).trimmed();
			if (!value.isEmpty()) {
				m_model = value;
				break;
			}
		}
	}
	if (m_model.isEmpty() || m_model == "Unknown Disk")
		m_model = m_device;

	// Capacity: /sys/block/<dev>/size is always reported in 512-byte sectors
	QFile sizeFile(base + "/size");
	if (sizeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		quint64 sectors = sizeFile.readAll().trimmed().toULongLong();
		m_capacity = sectors * 512;
	}

	// Rotational flag: 0 = SSD/flash, 1 = spinning HDD
	QFile rotFile(base + "/queue/rotational");
	if (rotFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		m_type = rotFile.readAll().trimmed().toInt() ? "HDD" : "SSD";
	}
}

bool DiskInfo::readDiskStats(const QString &device, DiskStats *out) const
{
	QFile f("/proc/diskstats");
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
		return false;

	// Same atEnd()-on-procfs pitfall as readStaticInfo() above.
	const QStringList lines = QString::fromUtf8(f.readAll()).split('\n');

	for (const QString &line : lines) {
		const QStringList parts = line.split(' ', Qt::SkipEmptyParts);
		// Fields (0-indexed): 0 major, 1 minor, 2 device name, 3 reads completed,
		// 4 reads merged, 5 sectors read, 6 ms reading, 7 writes completed,
		// 8 writes merged, 9 sectors written, 10 ms writing, 11 I/Os in flight,
		// 12 ms doing I/Os, 13 weighted ms doing I/Os.
		if (parts.size() < 14 || parts[2] != device)
			continue;

		out->readsCompleted  = parts[3].toULongLong();
		out->sectorsRead     = parts[5].toULongLong();
		out->readTicks        = parts[6].toULongLong();
		out->writesCompleted = parts[7].toULongLong();
		out->sectorsWritten   = parts[9].toULongLong();
		out->writeTicks       = parts[10].toULongLong();
		out->ioTicks           = parts[12].toULongLong();
		return true;
	}
	return false;
}

void DiskInfo::updateDiskStats()
{
	DiskStats current;
	bool ok = !m_device.isEmpty() && readDiskStats(m_device, &current);

	qint64 elapsedMs = m_timeTracker.restart();
	if (elapsedMs <= 0)
		elapsedMs = 1000;

	if (ok && m_hasPrevStats) {
		quint64 deltaIoTicks = current.ioTicks > m_prevStats.ioTicks
			? current.ioTicks - m_prevStats.ioTicks : 0;
		m_activeTime = qBound(0.0, static_cast<double>(deltaIoTicks) / static_cast<double>(elapsedMs), 1.0);

		quint64 deltaReadTicks = current.readTicks > m_prevStats.readTicks
			? current.readTicks - m_prevStats.readTicks : 0;
		quint64 deltaWriteTicks = current.writeTicks > m_prevStats.writeTicks
			? current.writeTicks - m_prevStats.writeTicks : 0;
		quint64 deltaReads = current.readsCompleted > m_prevStats.readsCompleted
			? current.readsCompleted - m_prevStats.readsCompleted : 0;
		quint64 deltaWrites = current.writesCompleted > m_prevStats.writesCompleted
			? current.writesCompleted - m_prevStats.writesCompleted : 0;
		quint64 deltaTransfers = deltaReads + deltaWrites;

		// Average time per completed I/O, in ms (matches iostat's "await").
		m_averageResponseTime = deltaTransfers > 0
			? static_cast<double>(deltaReadTicks + deltaWriteTicks) / static_cast<double>(deltaTransfers)
			: 0.0;

		quint64 deltaSectorsRead = current.sectorsRead > m_prevStats.sectorsRead
			? current.sectorsRead - m_prevStats.sectorsRead : 0;
		quint64 deltaSectorsWritten = current.sectorsWritten > m_prevStats.sectorsWritten
			? current.sectorsWritten - m_prevStats.sectorsWritten : 0;

		// Sectors are always 512 bytes, regardless of the disk's logical block size.
		m_readSpeed = (deltaSectorsRead * 512 * 1000) / static_cast<quint64>(elapsedMs);
		m_writeSpeed = (deltaSectorsWritten * 512 * 1000) / static_cast<quint64>(elapsedMs);
	} else {
		m_activeTime = 0.0;
		m_averageResponseTime = 0.0;
		m_readSpeed = 0;
		m_writeSpeed = 0;
	}

	if (ok) {
		m_totalRead = current.sectorsRead * 512;
		m_totalWritten = current.sectorsWritten * 512;
		m_prevStats = current;
		m_hasPrevStats = true;
	}

	m_activeTimeHistory.removeFirst();
	m_activeTimeHistory.append(m_activeTime);

	m_readSpeedHistory.removeFirst();
	m_readSpeedHistory.append(static_cast<double>(m_readSpeed));

	m_writeSpeedHistory.removeFirst();
	m_writeSpeedHistory.append(static_cast<double>(m_writeSpeed));

	// Track the peak transfer speed across the visible window so the read/write
	// bars below the graph (see DiskPage.qml) have something to scale against.
	quint64 windowPeak = 1; // avoid a zero-width bar when idle
	for (const QVariant &v : m_readSpeedHistory)
		windowPeak = qMax(windowPeak, static_cast<quint64>(v.toDouble()));
	for (const QVariant &v : m_writeSpeedHistory)
		windowPeak = qMax(windowPeak, static_cast<quint64>(v.toDouble()));
	m_peakSpeed = windowPeak;

	emit statsChanged();
	emit historyChanged();
}
