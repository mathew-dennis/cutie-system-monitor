#include "systemmonitor.h"

SystemMonitor::SystemMonitor(QObject *parent)
	: QObject(parent), m_cpu(this), m_memory(this), m_network(this)
{
	connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::poll);
	m_timer.start(m_intervalMs);

	poll();
}

void SystemMonitor::poll()
{
	// MemoryInfo and WifiInfo each run their own QTimer and update
	// themselves; CPU is the only sub-module driven from here.
	m_cpu.pollDynamicInfo(m_intervalMs, &SystemMonitor::pushHistory, kHistoryLength);
}

QVariantList SystemMonitor::pushHistory(QVariantList history, double value, int maxLen)
{
	history.append(value);
	while (history.size() > maxLen) {
		history.removeFirst();
	}
	return history;
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
