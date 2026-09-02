#pragma once

#include <QObject>
#include <QVariantList>
#include <QString>
#include <QTimer>
#include <QElapsedTimer>

class DiskInfo : public QObject
{
	Q_OBJECT

	// Static Properties (Read once at startup)
	Q_PROPERTY(QString model READ model CONSTANT)
	Q_PROPERTY(QString deviceName READ deviceName CONSTANT)
	Q_PROPERTY(quint64 capacity READ capacity CONSTANT)
	Q_PROPERTY(QString type READ type CONSTANT)
	Q_PROPERTY(bool isSystemDisk READ isSystemDisk CONSTANT)

	// Dynamic Properties (Polled periodically)
	Q_PROPERTY(double activeTime READ activeTime NOTIFY statsChanged)           // 0.0 - 1.0
	Q_PROPERTY(double averageResponseTime READ averageResponseTime NOTIFY statsChanged) // ms
	Q_PROPERTY(quint64 readSpeed READ readSpeed NOTIFY statsChanged)            // bytes/sec
	Q_PROPERTY(quint64 writeSpeed READ writeSpeed NOTIFY statsChanged)          // bytes/sec
	Q_PROPERTY(quint64 totalRead READ totalRead NOTIFY statsChanged)            // bytes, cumulative
	Q_PROPERTY(quint64 totalWritten READ totalWritten NOTIFY statsChanged)      // bytes, cumulative

	// Graph Data (last 60 seconds)
	Q_PROPERTY(QVariantList activeTimeHistory READ activeTimeHistory NOTIFY historyChanged)
	Q_PROPERTY(QVariantList readSpeedHistory READ readSpeedHistory NOTIFY historyChanged)
	Q_PROPERTY(QVariantList writeSpeedHistory READ writeSpeedHistory NOTIFY historyChanged)
	Q_PROPERTY(quint64 peakSpeed READ peakSpeed NOTIFY historyChanged) // max of both histories, for bar scaling

public:
	explicit DiskInfo(QObject *parent = nullptr);

	// Static Getters
	QString model() const { return m_model; }
	QString deviceName() const { return m_device; }
	quint64 capacity() const { return m_capacity; }
	QString type() const { return m_type; }
	bool isSystemDisk() const { return m_isSystemDisk; }

	// Dynamic Getters
	double activeTime() const { return m_activeTime; }
	double averageResponseTime() const { return m_averageResponseTime; }
	quint64 readSpeed() const { return m_readSpeed; }
	quint64 writeSpeed() const { return m_writeSpeed; }
	quint64 totalRead() const { return m_totalRead; }
	quint64 totalWritten() const { return m_totalWritten; }

	// Graph Getters
	QVariantList activeTimeHistory() const { return m_activeTimeHistory; }
	QVariantList readSpeedHistory() const { return m_readSpeedHistory; }
	QVariantList writeSpeedHistory() const { return m_writeSpeedHistory; }
	quint64 peakSpeed() const { return m_peakSpeed; }

public slots:
	void updateDiskStats();

signals:
	void statsChanged();
	void historyChanged();

private:
	struct DiskStats {
		quint64 sectorsRead = 0;
		quint64 sectorsWritten = 0;
		quint64 readTicks = 0;      // ms spent on reads
		quint64 writeTicks = 0;     // ms spent on writes
		quint64 ioTicks = 0;        // ms with >=1 I/O in flight (drives activeTime)
		quint64 readsCompleted = 0;
		quint64 writesCompleted = 0;
	};

	void detectPrimaryDisk();
	void readStaticInfo();
	bool readDiskStats(const QString &device, DiskStats *out) const;
	QString rootMountDevice() const;
	QString baseDeviceName(const QString &devicePath) const;

	// Static Data
	QString m_device; // e.g. "sda", "mmcblk0", "nvme0n1"
	QString m_model = "Unknown Disk";
	quint64 m_capacity = 0;
	QString m_type = "N/A";
	bool m_isSystemDisk = false;

	// Dynamic Data
	double m_activeTime = 0.0;
	double m_averageResponseTime = 0.0;
	quint64 m_readSpeed = 0;
	quint64 m_writeSpeed = 0;
	quint64 m_totalRead = 0;
	quint64 m_totalWritten = 0;

	// Graph / History Data
	QVariantList m_activeTimeHistory;
	QVariantList m_readSpeedHistory;
	QVariantList m_writeSpeedHistory;
	quint64 m_peakSpeed = 1; // avoid a zero-width scale when idle
	static constexpr int MAX_HISTORY_POINTS = 60;

	// Internal tracking for delta calculations
	DiskStats m_prevStats;
	bool m_hasPrevStats = false;
	QElapsedTimer m_timeTracker;

	QTimer *m_updateTimer;
};
