#ifndef WIFIINFO_H
#define WIFIINFO_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QTimer>
#include <QElapsedTimer>

class WifiInfo : public QObject
{
    Q_OBJECT

    // Static / Connection Details
    Q_PROPERTY(QString adapterName READ adapterName NOTIFY connectionInfoChanged)
    Q_PROPERTY(QString interfaceName READ interfaceName NOTIFY connectionInfoChanged)
    Q_PROPERTY(QString connectionType READ connectionType CONSTANT)
    Q_PROPERTY(QString ssid READ ssid NOTIFY connectionInfoChanged)
    Q_PROPERTY(QString frequency READ frequency NOTIFY connectionInfoChanged)
    Q_PROPERTY(QString hardwareAddress READ hardwareAddress CONSTANT)
    Q_PROPERTY(QString ipv4Address READ ipv4Address NOTIFY connectionInfoChanged)
    Q_PROPERTY(QString ipv6Address READ ipv6Address NOTIFY connectionInfoChanged)

    // Dynamic Live Metrics
    Q_PROPERTY(quint64 receiveSpeed READ receiveSpeed NOTIFY statsChanged)
    Q_PROPERTY(quint64 sendSpeed READ sendSpeed NOTIFY statsChanged)
    Q_PROPERTY(quint64 totalReceived READ totalReceived NOTIFY statsChanged)
    Q_PROPERTY(quint64 totalSent READ totalSent NOTIFY statsChanged)
    Q_PROPERTY(int signalStrength READ signalStrength NOTIFY statsChanged) // 0 - 100 %

    // Graph Throughput History (Last 60 seconds)
    Q_PROPERTY(QVariantList receiveHistory READ receiveHistory NOTIFY historyChanged)
    Q_PROPERTY(QVariantList sendHistory READ sendHistory NOTIFY historyChanged)

public:
    explicit WifiInfo(QObject *parent = nullptr);

    // Static / Connection Getters
    QString adapterName() const;
    QString interfaceName() const;
    QString connectionType() const;
    QString ssid() const;
    QString frequency() const;
    QString hardwareAddress() const;
    QString ipv4Address() const;
    QString ipv6Address() const;

    // Dynamic Getters
    quint64 receiveSpeed() const;
    quint64 sendSpeed() const;
    quint64 totalReceived() const;
    quint64 totalSent() const;
    int signalStrength() const;

    // History Getters
    QVariantList receiveHistory() const;
    QVariantList sendHistory() const;

public slots:
    void updateWifiStats();

signals:
    void connectionInfoChanged();
    void statsChanged();
    void historyChanged();

private:
    // Static & Connection state
    QString m_adapterName;
    QString m_interfaceName;
    QString m_connectionType;
    QString m_ssid;
    QString m_frequency;
    QString m_hardwareAddress;
    QString m_ipv4Address;
    QString m_ipv6Address;

    // Dynamic state
    quint64 m_receiveSpeed;
    quint64 m_sendSpeed;
    quint64 m_totalReceived;
    quint64 m_totalSent;
    int m_signalStrength;

    // Internal tracking for speed calculation
    quint64 m_prevRxBytes;
    quint64 m_prevTxBytes;
    QElapsedTimer m_timeTracker;

    // History buffers (60 data points for 1-minute graph)
    QVariantList m_receiveHistory;
    QVariantList m_sendHistory;
    const int MAX_HISTORY_POINTS = 60;

    QTimer *m_updateTimer;

    // Internal helper methods
    void detectInterface();
    void updateNetworkAddresses();
    void updateWirelessDetails();
    quint64 readSysfsValue(const QString &filename) const;
};

#endif // WIFIINFO_H