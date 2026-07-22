#include "systemmonitor.h"

#include <QFile>
#include <QTextStream>

SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent)
{
	// Prime the "previous" samples so the first poll() doesn't report a
	// bogus 100% spike from a zero baseline.
	readProcStat(&m_prevCpuTimes);
	m_coreCount = qMax(0, m_prevCpuTimes.size() - 1); // index 0 is the aggregate "cpu" line
	readNetwork();

	connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::poll);
	m_timer.start(m_intervalMs);

	// Run one poll immediately so pages have data as soon as they're shown
	// instead of waiting a full interval.
	poll();
}

void SystemMonitor::poll()
{
	readCpu();
	readMemory();
	readNetwork();
}

bool SystemMonitor::readProcStat(QList<CpuTimes> *out)
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

		// user nice system idle iowait irq softirq steal ...
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

void SystemMonitor::pushHistory(QVariantList *history, double value, int maxLen)
{
	// Create a shallow copy to force a new memory reference
	QVariantList newList = *history;
	
	newList.append(value);
	while (newList.size() > maxLen) {
		newList.removeFirst();
	}
	
	// Assign the new list back to the pointer
	*history = newList;
}

void SystemMonitor::readCpu()
{
	QList<CpuTimes> current;
	if (!readProcStat(&current) || current.size() != m_prevCpuTimes.size()) {
		m_prevCpuTimes = current;
		return;
	}

	QVariantList perCore;
	double aggregateUsage = 0.0;

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
		}
	}

	m_cpuUsage = aggregateUsage;
	m_perCoreUsage = perCore;
	pushHistory(&m_cpuHistory, aggregateUsage, kHistoryLength);
	m_prevCpuTimes = current;

	emit cpuChanged();
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

		// Values in /proc/meminfo are reported in kB.
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
	pushHistory(&m_memHistory, usedFraction, kHistoryLength);

	emit memChanged();
}

void SystemMonitor::readNetwork()
{
	QFile f("/proc/net/dev");
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
		return;

	QTextStream in(&f);
	// Skip the two header lines.
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

	// Normalise against a soft ceiling so the graph has a sensible scale
	// even on quiet links; the LineGraph component still auto-scales to
	// whatever the actual max in the window is.
	pushHistory(&m_netRxHistory, static_cast<double>(rxRateSum), kHistoryLength);
	pushHistory(&m_netTxHistory, static_cast<double>(txRateSum), kHistoryLength);

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
