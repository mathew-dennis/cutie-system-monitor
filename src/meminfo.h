#ifndef MEMORYINFO_H
#define MEMORYINFO_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QTimer>

class MemoryInfo : public QObject
{
    Q_OBJECT

    // Static Properties (Read once, no notify needed)
    Q_PROPERTY(quint64 total READ total CONSTANT)
    Q_PROPERTY(QString speed READ speed CONSTANT)
    Q_PROPERTY(QString slots READ slots CONSTANT)
    Q_PROPERTY(QString formFactor READ formFactor CONSTANT)
    Q_PROPERTY(QString type READ type CONSTANT)
    Q_PROPERTY(quint64 swapTotal READ swapTotal CONSTANT)

    // Dynamic Properties (Updated periodically)
    Q_PROPERTY(quint64 inUse READ inUse NOTIFY memoryChanged)
    Q_PROPERTY(quint64 committed READ committed NOTIFY memoryChanged)
    Q_PROPERTY(quint64 cache READ cache NOTIFY memoryChanged)
    Q_PROPERTY(quint64 swapUsed READ swapUsed NOTIFY memoryChanged)
    
    // Graph Data
    Q_PROPERTY(QVariantList usageHistory READ usageHistory NOTIFY historyChanged)

public:
    explicit MemoryInfo(QObject *parent = nullptr);

    // Static Getters
    quint64 total() const;
    QString speed() const;
    QString slots() const;
    QString formFactor() const;
    QString type() const;
    quint64 swapTotal() const;

    // Dynamic Getters
    quint64 inUse() const;
    quint64 committed() const;
    quint64 cache() const;
    quint64 swapUsed() const;
    QVariantList usageHistory() const;

public slots:
    void updateMemoryStats();

signals:
    void memoryChanged();
    void historyChanged();

private:
    // Static members
    quint64 m_total;
    QString m_speed;
    QString m_slots;
    QString m_formFactor;
    QString m_type;
    quint64 m_swapTotal;

    // Dynamic members
    quint64 m_inUse;
    quint64 m_committed;
    quint64 m_cache;
    quint64 m_swapUsed;

    // Graph history buffer
    QVariantList m_usageHistory;
    const int MAX_HISTORY_POINTS = 60; // E.g., 60 seconds of data

    QTimer *m_updateTimer;

    // Helper functions
    void initStaticInfo();
    quint64 extractKbToBytes(const QString &line) const;
};

#endif // MEMORYINFO_H