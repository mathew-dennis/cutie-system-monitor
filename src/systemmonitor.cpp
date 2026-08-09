#include "systemmonitor.h"

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <sys/sysinfo.h>

// ============================================================================
// CPU MONITOR MODULE IMPLEMENTATION
// ============================================================================

CpuInfo::CpuInfo(QObject *parent) : QObject(parent)
{
	readProcStat(&m_prevCpuTimes);
	m_coreCount = qMax(0, m_prevCpuTimes.size() - 1);
	readStaticInfo();
}

void CpuInfo::readStaticInfo()
{
	// 1. Read CPU Model Name
	QFile cpuInfoFile("/proc/cpuinfo");
	if (cpuInfoFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		QTextStream in(&cpuInfoFile);
		while (!in.atEnd()) {
			QString line = in.readLine();
			if (line.startsWith("model name") || line.startsWith("Hardware")) {
				int colon = line.indexOf(':');
				if (colon != -1) {
					m_name = line.mid(colon + 1).trimmed();
					break;
				}
			}
		}
	}

	// 2. Read Base Speed from cpufreq
	QFile baseFreqFile("/sys/devices/system/cpu/cpu0/cpufreq/base_frequency");
	if (!baseFreqFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		baseFreqFile.setFileName("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq");
		baseFreqFile.open(QIODevice::ReadOnly | QIODevice::Text);
	}
	if (baseFreqFile.isOpen()) {
		QTextStream in(&baseFreqFile);
		double khz = in.readLine().trimmed().toDouble();
		if (khz > 0) {
			m_baseSpeed = QString::number(khz / 1000000.0, 'f', 2) + " GHz";
		}
	}

	// 3. Read Cache Sizes (L1, L2, L3)
	quint64 l1SizeBytes = 0;
	QDir cacheDir("/sys/devices/system/cpu/cpu0/cache");
	QStringList indexDirs = cacheDir.entryList(QStringList() << "index*", QDir::Dirs);

	for (const QString &dirName : indexDirs) {
		QString basePath = cacheDir.absoluteFilePath(dirName);
		
		// Read Cache Level
		QFile levelFile(basePath + "/level");
		int level = 0;
		if (levelFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
			level = levelFile.readAll().trimmed().toInt();
		}

		// Read Cache Size String
		QFile sizeFile(basePath + "/size");
		QString sizeStr = "0";
		if (sizeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
			sizeStr = sizeFile.readAll().trimmed();
		}

		// Parse size into bytes for accumulation
		quint64 bytes = 0;
		if (sizeStr.endsWith('K', Qt::CaseInsensitive)) {
			bytes = sizeStr.left(sizeStr.length() - 1).toULongLong() * 1024;
		} else if (sizeStr.endsWith('M', Qt::CaseInsensitive)) {
			bytes = sizeStr.left(sizeStr.length() - 1).toULongLong() * 1024 * 1024;
		}

		if (level == 1) {
			l1SizeBytes += bytes; // Sum L1d + L1i
		} else if (level == 2) {
			m_l2Cache = sizeStr;
		} else if (level == 3) {
			m_l3Cache = sizeStr;
		}
	}

	if (l1SizeBytes > 0) {
		m_l1Cache = QString::number(l1SizeBytes / 1024) + " KB";
	}
}

bool CpuInfo::readProcStat(QList<CpuTimes> *out)
{
	QFile f("/proc/stat");
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
		return false;

	QTextStream in(&f);
	out->clear();

	while (!in.atEnd()) {
		QString line = in.readLine();
		if (!line.startsWith("cpu"))
			break;

		QStringList parts = line.split(' ', Qt::SkipEmptyParts);
		if (parts.size() < 8)
			continue;

		quint64 user = parts[1].toULongLong();
		quint64 nice = parts[2].toULongLong();
		quint64 system = parts[3].toULongLong();
		quint64 idle = parts[4].toULongLong();
		quint64 iowait = parts[5].toULongLong();
		quint64 irq = parts[6].toULongLong();
		quint64 softirq = parts[7].toULongLong();
		quint64 steal = parts.size() > 8 ? parts[8].toULongLong() : 0;

		CpuTimes t;
		t.idle = idle + iowait;
		t.total = user + nice + system + idle + iowait + irq + softirq + steal;
		out->append(t);
	}

	return !out->isEmpty();
}

void CpuInfo::updateFrequenciesAndUsage(const QList<CpuTimes> &current)
{
	QVariantList perCore;
	double aggregateUsage = 0.0;
	double weightedFreqSum = 0.0;
	double totalUtilSum = 0.0;

	for (int i = 0; i < current.size(); ++i) {
		quint64 deltaIdle = current[i].idle - m_prevCpuTimes[i].idle;
		quint64 deltaTotal = current[i].total - m_prevCpuTimes[i].total;

		double usage = deltaTotal > 0
			? 1.0 - (static_cast<double>(deltaIdle) / static_cast<double>(deltaTotal))
			: 0.0;
		usage = qBound(0.0, usage, 1.0);

		if (i == 0) {
			aggregateUsage = usage;
		} else {
			perCore.append(usage);

			// Read current frequency for active logical processor
			QFile freqFile(QString("/sys/devices/system/cpu/cpu%1/cpufreq/scaling_cur_freq").arg(i - 1));
			if (freqFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
				double khz = freqFile.readLine().trimmed().toDouble();
				double ghz = khz / 1000000.0;
				weightedFreqSum += ghz * usage;
				totalUtilSum += usage;
			}
		}
	}

	m_utilization = aggregateUsage;
	m_perCoreUsage = perCore;

	// Calculate Utilization-Weighted Average Clock Speed
	if (totalUtilSum > 0.001) {
		m_speed = QString::number(weightedFreqSum / totalUtilSum, 'f', 2) + " GHz";
	} else if (m_coreCount > 0) {
		// Fallback to average scaling speed if idle
		double sumGhz = 0.0;
		for (int i = 0; i < m_coreCount; ++i) {
			QFile freqFile(QString("/sys/devices/system/cpu/cpu%1/cpufreq/scaling_cur_freq").arg(i));
			if (freqFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
				sumGhz += (freqFile.readLine().trimmed().toDouble() / 1000000.0);
			}
		}
		m_speed = QString::number(sumGhz / m_coreCount, 'f', 2) + " GHz";
	}
}

void CpuInfo::updateSystemCounters()
{
	// 1. Read Processes & Uptime using standard sysinfo
	struct sysinfo info;
	if (sysinfo(&info) == 0) {
		m_processes = info.procs;

		long secs = info.uptime;
		long days = secs / 86400;
		long hours = (secs % 86400) / 3600;
		long mins = (secs % 3600) / 60;
		long s = secs % 60;

		m_uptime = QString("%1:%2:%3:%4")
			.arg(days)
			.arg(hours, 2, 10, QChar('0'))
			.arg(mins, 2, 10, QChar('0'))
			.arg(s, 2, 10, QChar('0'));
	}

	// 2. Read Thread Count from /proc/loadavg
	QFile loadAvgFile("/proc/loadavg");
	if (loadAvgFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		QStringList parts = QString(loadAvgFile.readAll()).split(' ', Qt::SkipEmptyParts);
		if (parts.size() >= 4) {
			QStringList threadParts = parts[3].split('/');
			if (threadParts.size() == 2) {
				m_threads = threadParts[1].toULongLong();
			}
		}
	}

	// 3. Read Allocated Handles / File Descriptors from /proc/sys/fs/file-nr
	QFile handleFile("/proc/sys/fs/file-nr");
	if (handleFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		QStringList parts = QString(handleFile.readAll()).split('\t', Qt::SkipEmptyParts);
		if (!parts.isEmpty()) {
			m_handles = parts[0].trimmed().toULongLong();
		}
	}
}

void CpuInfo::pollDynamicInfo(int intervalMs, QVariantList (*pushHistoryFunc)(QVariantList, double, int), int maxHistory)
{
	QList<CpuTimes> current;
	if (!readProcStat(&current) || current.size() != m_prevCpuTimes.size()) {
		m_prevCpuTimes = current;
		return;
	}

	updateFrequenciesAndUsage(current);
	updateSystemCounters();

	m_history = pushHistoryFunc(m_history, m_utilization, maxHistory);
	m_prevCpuTimes = current;

	emit updated();
}

// ============================================================================
// MAIN SYSTEM MONITOR IMPLEMENTATION
// ============================================================================

SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent), m_cpu(this)
{
	readNetwork();

	connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::poll);
	m_timer.start(m_intervalMs);

	poll();
}

void SystemMonitor::poll()
{
	m_cpu.pollDynamicInfo(m_intervalMs, &SystemMonitor::pushHistory, kHistoryLength);
	readMemory();
	readNetwork();
}

QVariantList SystemMonitor::pushHistory(QVariantList history, double value, int maxLen)
{
	history.append(value);
	while (history.size() > maxLen) {
		history.removeFirst();
	}
	return history;
}

void SystemMonitor::readMemory()
{
	QFile f("/proc/meminfo");
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
		return;

	QMap<QString, quint64> values;
	QTextStream in(&f);
	while (!in.atEnd()) {
		QString line = in.readLine();
		int colon = line.indexOf(':');
		if (colon < 0)
			continue;

		QString key = line.left(colon);
		QString rest = line.mid(colon + 1).trimmed();
		QStringList parts = rest.split(' ', Qt::SkipEmptyParts);
		if (parts.isEmpty())
			continue;

		values[key] = parts[0].toULongLong() * 1024;
	}

	m_memTotal = values.value("MemTotal");
	quint64 memFree = values.value("MemFree");
	quint64 memAvailable = values.contains("MemAvailable") ? values.value("MemAvailable") : memFree;
	m_memAvailable = memAvailable;
	m_memUsed = m_memTotal > memAvailable ? m_memTotal - memAvailable : 0;
	m_memBuffers = values.value("Buffers");
	m_memCached = values.value("Cached") + values.value("SReclaimable");
	m_swapTotal = values.value("SwapTotal");
	quint64 swapFree = values.value("SwapFree");
	m_swapUsed = m_swapTotal > swapFree ? m_swapTotal - swapFree : 0;

	double usedFraction = m_memTotal > 0
		? static_cast<double>(m_memUsed) / static_cast<double>(m_memTotal)
		: 0.0;
	m_memHistory = pushHistory(m_memHistory, usedFraction, kHistoryLength);

	emit memChanged();
}

void SystemMonitor::readNetwork()
{
	QFile f("/proc/net/dev");
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
		return;

	QTextStream in(&f);
	if (!in.atEnd())
		in.readLine();
	if (!in.atEnd())
		in.readLine();

	QMap<QString, NetSample> current;
	QVariantList interfaces;
	quint64 rxRateSum = 0;
	quint64 txRateSum = 0;
	quint64 rxBytesSum = 0;
	quint64 txBytesSum = 0;

	while (!in.atEnd()) {
		QString line = in.readLine();
		int colon = line.indexOf(':');
		if (colon < 0)
			continue;

		QString iface = line.left(colon).trimmed();
		QStringList parts = line.mid(colon + 1).trimmed().split(' ', Qt::SkipEmptyParts);
		if (parts.size() < 9 || iface == "lo")
			continue;

		NetSample sample;
		sample.rx = parts[0].toULongLong();
		sample.tx = parts[8].toULongLong();
		current[iface] = sample;

		quint64 rxRate = 0;
		quint64 txRate = 0;
		if (m_prevNet.contains(iface)) {
			const NetSample &prev = m_prevNet[iface];
			quint64 deltaRx = sample.rx >= prev.rx ? sample.rx - prev.rx : 0;
			quint64 deltaTx = sample.tx >= prev.tx ? sample.tx - prev.tx : 0;
			rxRate = deltaRx * 1000 / static_cast<quint64>(m_intervalMs);
			txRate = deltaTx * 1000 / static_cast<quint64>(m_intervalMs);
		}

		QVariantMap entry;
		entry["name"] = iface;
		entry["rxRate"] = static_cast<qulonglong>(rxRate);
		entry["txRate"] = static_cast<qulonglong>(txRate);
		entry["rxBytes"] = static_cast<qulonglong>(sample.rx);
		entry["txBytes"] = static_cast<qulonglong>(sample.tx);
		interfaces.append(entry);

		rxRateSum += rxRate;
		txRateSum += txRate;
		rxBytesSum += sample.rx;
		txBytesSum += sample.tx;
	}

	m_networkInterfaces = interfaces;
	m_totalRxRate = rxRateSum;
	m_totalTxRate = txRateSum;
	m_totalRxBytes = rxBytesSum;
	m_totalTxBytes = txBytesSum;
	m_prevNet = current;

	m_netRxHistory = pushHistory(m_netRxHistory, static_cast<double>(rxRateSum), kHistoryLength);
	m_netTxHistory = pushHistory(m_netTxHistory, static_cast<double>(txRateSum), kHistoryLength);

	emit netChanged();
}

QString SystemMonitor::formatBytes(quint64 bytes) const
{
	static const char *units[] = { "B", "KB", "MB", "GB", "TB" };
	double value = static_cast<double>(bytes);
	int unit = 0;
	while (value >= 1024.0 && unit < 4) {
		value /= 1024.0;
		++unit;
	}
	return QString::number(value, 'f', unit == 0 ? 0 : 1) + " " + units[unit];
}

QString SystemMonitor::formatRate(quint64 bytesPerSec) const
{
	return formatBytes(bytesPerSec) + "/s";
}
