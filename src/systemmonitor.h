#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QMap>
#include <QString>
#include <QList>

// ============================================================================
// CPU MONITOR MODULE (Moved to Top)
// ============================================================================

class CpuInfo : public QObject
{
	Q_OBJECT

	// Static Properties (Read once at startup)
	Q_PROPERTY(QString name READ name CONSTANT)
	Q_PROPERTY(int coreCount READ coreCount CONSTANT)
	Q_PROPERTY(QString baseSpeed READ baseSpeed CONSTANT)
	Q_PROPERTY(QString l1Cache READ l1Cache CONSTANT)
	Q_PROPERTY(QString l2Cache READ l2Cache CONSTANT)
	Q_PROPERTY(QString l3Cache READ l3Cache CONSTANT)

	// Dynamic Properties (Polled periodically)
	Q_PROPERTY(double utilization READ utilization NOTIFY updated)
	Q_PROPERTY(QString speed READ speed NOTIFY updated)
	Q_PROPERTY(quint64 threads READ threads NOTIFY updated)
	Q_PROPERTY(quint64 processes READ processes NOTIFY updated)
	Q_PROPERTY(quint64 handles READ handles NOTIFY updated)
	Q_PROPERTY(QString uptime READ uptime NOTIFY updated)

	// Graph Data
	Q_PROPERTY(QVariantList history READ history NOTIFY updated)
	Q_PROPERTY(QVariantList perCoreUsage READ perCoreUsage NOTIFY updated)

public:
	explicit CpuInfo(QObject *parent = nullptr);

	// Static Getters
	QString name() const { return m_name; }
	int coreCount() const { return m_coreCount; }
	QString baseSpeed() const { return m_baseSpeed; }
	QString l1Cache() const { return m_l1Cache; }
	QString l2Cache() const { return m_l2Cache; }
	QString l3Cache() const { return m_l3Cache; }

	// Dynamic Getters
	double utilization() const { return m_utilization; }
	QString speed() const { return m_speed; }
	quint64 threads() const { return m_threads; }
	quint64 processes() const { return m_processes; }
	quint64 handles() const { return m_handles; }
	QString uptime() const { return m_uptime; }

	// Graph Getters
	QVariantList history() const { return m_history; }
	QVariantList perCoreUsage() const { return m_perCoreUsage; }

	void readStaticInfo();
	void pollDynamicInfo(int intervalMs, QVariantList (*pushHistoryFunc)(QVariantList, double, int), int maxHistory);

signals:
	void updated();

private:
	struct CpuTimes {
		quint64 idle = 0;
		quint64 total = 0;
	};

	bool readProcStat(QList<CpuTimes> *out);
	void updateFrequenciesAndUsage(const QList<CpuTimes> &current);
	void updateSystemCounters();

	// Static Data
	QString m_name = "Unknown Processor";
	int m_coreCount = 0;
	QString m_baseSpeed = "N/A";
	QString m_l1Cache = "N/A";
	QString m_l2Cache = "N/A";
	QString m_l3Cache = "N/A";

	// Dynamic Data
	double m_utilization = 0.0;
	QString m_speed = "0.00 GHz";
	quint64 m_threads = 0;
	quint64 m_processes = 0;
	quint64 m_handles = 0;
	QString m_uptime = "0:00:00:00";

	// Graph / Multi-core Data
	QVariantList m_history;
	QVariantList m_perCoreUsage;
	QList<CpuTimes> m_prevCpuTimes;
};

// ============================================================================
// SYSTEM MONITOR MAIN CLASS
// ============================================================================

class SystemMonitor : public QObject
{
	Q_OBJECT

	// CPU Property Object (Access via cpu.name, cpu.utilization, cpu.history, etc.)
	Q_PROPERTY(CpuInfo* cpu READ cpu CONSTANT)

	// Memory Properties
	Q_PROPERTY(quint64 memTotal READ memTotal NOTIFY memChanged)
	Q_PROPERTY(quint64 memUsed READ memUsed NOTIFY memChanged)
	Q_PROPERTY(quint64 memAvailable READ memAvailable NOTIFY memChanged)
	Q_PROPERTY(quint64 memCached READ memCached NOTIFY memChanged)
	Q_PROPERTY(quint64 memBuffers READ memBuffers NOTIFY memChanged)
	Q_PROPERTY(quint64 swapTotal READ swapTotal NOTIFY memChanged)
	Q_PROPERTY(quint64 swapUsed READ swapUsed NOTIFY memChanged)
	Q_PROPERTY(QVariantList memHistory READ memHistory NOTIFY memChanged)

	// Network Properties
	Q_PROPERTY(QVariantList networkInterfaces READ networkInterfaces NOTIFY netChanged)
	Q_PROPERTY(quint64 totalRxRate READ totalRxRate NOTIFY netChanged)
	Q_PROPERTY(quint64 totalTxRate READ totalTxRate NOTIFY netChanged)
	Q_PROPERTY(quint64 totalRxBytes READ totalRxBytes NOTIFY netChanged)
	Q_PROPERTY(quint64 totalTxBytes READ totalTxBytes NOTIFY netChanged)
	Q_PROPERTY(QVariantList netRxHistory READ netRxHistory NOTIFY netChanged)
	Q_PROPERTY(QVariantList netTxHistory READ netTxHistory NOTIFY netChanged)

public:
	explicit SystemMonitor(QObject *parent = nullptr);

	CpuInfo* cpu() { return &m_cpu; }

	// Memory Getters
	quint64 memTotal() const { return m_memTotal; }
	quint64 memUsed() const { return m_memUsed; }
	quint64 memAvailable() const { return m_memAvailable; }
	quint64 memCached() const { return m_memCached; }
	quint64 memBuffers() const { return m_memBuffers; }
	quint64 swapTotal() const { return m_swapTotal; }
	quint64 swapUsed() const { return m_swapUsed; }
	QVariantList memHistory() const { return m_memHistory; }

	// Network Getters
	QVariantList networkInterfaces() const { return m_networkInterfaces; }
	quint64 totalRxRate() const { return m_totalRxRate; }
	quint64 totalTxRate() const { return m_totalTxRate; }
	quint64 totalRxBytes() const { return m_totalRxBytes; }
	quint64 totalTxBytes() const { return m_totalTxBytes; }
	QVariantList netRxHistory() const { return m_netRxHistory; }
	QVariantList netTxHistory() const { return m_netTxHistory; }

	Q_INVOKABLE QString formatBytes(quint64 bytes) const;
	Q_INVOKABLE QString formatRate(quint64 bytesPerSec) const;

	static QVariantList pushHistory(QVariantList history, double value, int maxLen);

signals:
	void memChanged();
	void netChanged();

private slots:
	void poll();

private:
	struct NetSample {
		quint64 rx = 0;
		quint64 tx = 0;
	};

	void readMemory();
	void readNetwork();

	QTimer m_timer;
	int m_intervalMs = 1000;

	// CPU Instance
	CpuInfo m_cpu;

	// Memory
	quint64 m_memTotal = 0;
	quint64 m_memUsed = 0;
	quint64 m_memAvailable = 0;
	quint64 m_memCached = 0;
	quint64 m_memBuffers = 0;
	quint64 m_swapTotal = 0;
	quint64 m_swapUsed = 0;
	QVariantList m_memHistory;

	// Network
	QMap<QString, NetSample> m_prevNet;
	QVariantList m_networkInterfaces;
	quint64 m_totalRxRate = 0;
	quint64 m_totalTxRate = 0;
	quint64 m_totalRxBytes = 0;
	quint64 m_totalTxBytes = 0;
	QVariantList m_netRxHistory;
	QVariantList m_netTxHistory;

	static const int kHistoryLength = 60;
};
