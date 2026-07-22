#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QMap>
#include <QString>

// SystemMonitor polls /proc for CPU, memory, and network statistics on a
// timer and exposes them to QML as a singleton (Cutie.SysMonitor 1.0).
class SystemMonitor : public QObject
{
	Q_OBJECT

	Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY cpuChanged)
	Q_PROPERTY(QVariantList perCoreUsage READ perCoreUsage NOTIFY cpuChanged)
	Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY cpuChanged)
	Q_PROPERTY(int coreCount READ coreCount CONSTANT)

	Q_PROPERTY(quint64 memTotal READ memTotal NOTIFY memChanged)
	Q_PROPERTY(quint64 memUsed READ memUsed NOTIFY memChanged)
	Q_PROPERTY(quint64 memAvailable READ memAvailable NOTIFY memChanged)
	Q_PROPERTY(quint64 memCached READ memCached NOTIFY memChanged)
	Q_PROPERTY(quint64 memBuffers READ memBuffers NOTIFY memChanged)
	Q_PROPERTY(quint64 swapTotal READ swapTotal NOTIFY memChanged)
	Q_PROPERTY(quint64 swapUsed READ swapUsed NOTIFY memChanged)
	Q_PROPERTY(QVariantList memHistory READ memHistory NOTIFY memChanged)

	Q_PROPERTY(QVariantList networkInterfaces READ networkInterfaces NOTIFY netChanged)
	Q_PROPERTY(quint64 totalRxRate READ totalRxRate NOTIFY netChanged)
	Q_PROPERTY(quint64 totalTxRate READ totalTxRate NOTIFY netChanged)
	Q_PROPERTY(quint64 totalRxBytes READ totalRxBytes NOTIFY netChanged)
	Q_PROPERTY(quint64 totalTxBytes READ totalTxBytes NOTIFY netChanged)
	Q_PROPERTY(QVariantList netRxHistory READ netRxHistory NOTIFY netChanged)
	Q_PROPERTY(QVariantList netTxHistory READ netTxHistory NOTIFY netChanged)

    public:
	explicit SystemMonitor(QObject *parent = nullptr);

	double cpuUsage() const { return m_cpuUsage; }
	QVariantList perCoreUsage() const { return m_perCoreUsage; }
	QVariantList cpuHistory() const { return m_cpuHistory; }
	int coreCount() const { return m_coreCount; }

	quint64 memTotal() const { return m_memTotal; }
	quint64 memUsed() const { return m_memUsed; }
	quint64 memAvailable() const { return m_memAvailable; }
	quint64 memCached() const { return m_memCached; }
	quint64 memBuffers() const { return m_memBuffers; }
	quint64 swapTotal() const { return m_swapTotal; }
	quint64 swapUsed() const { return m_swapUsed; }
	QVariantList memHistory() const { return m_memHistory; }

	QVariantList networkInterfaces() const { return m_networkInterfaces; }
	quint64 totalRxRate() const { return m_totalRxRate; }
	quint64 totalTxRate() const { return m_totalTxRate; }
	quint64 totalRxBytes() const { return m_totalRxBytes; }
	quint64 totalTxBytes() const { return m_totalTxBytes; }
	QVariantList netRxHistory() const { return m_netRxHistory; }
	QVariantList netTxHistory() const { return m_netTxHistory; }

	Q_INVOKABLE QString formatBytes(quint64 bytes) const;
	Q_INVOKABLE QString formatRate(quint64 bytesPerSec) const;

    signals:
	void cpuChanged();
	void memChanged();
	void netChanged();

    private slots:
	void poll();

    private:
	struct CpuTimes {
		quint64 idle = 0;
		quint64 total = 0;
	};
	struct NetSample {
		quint64 rx = 0;
		quint64 tx = 0;
	};

	void readCpu();
	void readMemory();
	void readNetwork();

	static bool readProcStat(QList<CpuTimes> *out);
	static QVariantList pushHistory(QVariantList history, double value, int maxLen);

	QTimer m_timer;
	int m_intervalMs = 1000;

	// CPU
	QList<CpuTimes> m_prevCpuTimes;
	double m_cpuUsage = 0.0;
	QVariantList m_perCoreUsage;
	QVariantList m_cpuHistory;
	int m_coreCount = 0;

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
