#pragma once

#include <QObject>
#include <QVariantList>
#include <QString>
#include <QList>

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
