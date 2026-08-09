#include "memoryinfo.h"
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QDebug>

MemoryInfo::MemoryInfo(QObject *parent)
    : QObject(parent),
      m_total(0), m_swapTotal(0),
      m_inUse(0), m_committed(0), m_cache(0), m_swapUsed(0)
{
    // Populate graph with initial zeroes to prevent UI shifting
    for (int i = 0; i < MAX_HISTORY_POINTS; ++i) {
        m_usageHistory.append(0.0);
    }

    initStaticInfo();

    // Setup polling timer (e.g., update every 1 second)
    m_updateTimer = new QTimer(this);
    connect(m_updateTimer, &QTimer::timeout, this, &MemoryInfo::updateMemoryStats);
    m_updateTimer->start(1000); 
    
    // Initial fetch
    updateMemoryStats();
}

void MemoryInfo::initStaticInfo()
{
    // Read total RAM and total Swap from /proc/meminfo once
    QFile file("/proc/meminfo");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("MemTotal:")) {
                m_total = extractKbToBytes(line);
            } else if (line.startsWith("SwapTotal:")) {
                m_swapTotal = extractKbToBytes(line);
            }
        }
        file.close();
    }

    // Hardware specifics (SMBIOS/DMI) usually require root access via dmidecode 
    // or reading /sys/class/dmi/id/. Using placeholders for layout purposes.
    m_speed = "3200 MHz"; 
    m_slots = "2 of 4";
    m_formFactor = "SODIMM";
    m_type = "DDR4";
}

void MemoryInfo::updateMemoryStats()
{
    quint64 memFree = 0, buffers = 0, cached = 0;
    quint64 swapFree = 0;
    quint64 committedAS = 0;

    QFile file("/proc/meminfo");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("MemAvailable:")) {
                // MemAvailable is a better indicator of free memory than MemFree
                memFree = extractKbToBytes(line);
            } else if (line.startsWith("Buffers:")) {
                buffers = extractKbToBytes(line);
            } else if (line.startsWith("Cached:")) {
                cached = extractKbToBytes(line);
            } else if (line.startsWith("SwapFree:")) {
                swapFree = extractKbToBytes(line);
            } else if (line.startsWith("Committed_AS:")) {
                committedAS = extractKbToBytes(line);
            }
        }
        file.close();

        // Calculate dynamic properties
        m_cache = cached + buffers;
        m_inUse = m_total > memFree ? (m_total - memFree) : 0;
        m_swapUsed = m_swapTotal > swapFree ? (m_swapTotal - swapFree) : 0;
        m_committed = committedAS;

        // Calculate percentage for the graph
        double usagePercentage = 0.0;
        if (m_total > 0) {
            usagePercentage = (static_cast<double>(m_inUse) / static_cast<double>(m_total)) * 100.0;
        }

        // Update history for the graph
        m_usageHistory.removeFirst();
        m_usageHistory.append(usagePercentage);

        emit memoryChanged();
        emit historyChanged();
    }
}

quint64 MemoryInfo::extractKbToBytes(const QString &line) const
{
    // Extracts the numeric value from a line like "MemTotal:       16382436 kB"
    QRegularExpression re("\\d+");
    QRegularExpressionMatch match = re.match(line);
    if (match.hasMatch()) {
        return match.captured(0).toULongLong() * 1024; // Convert kB to Bytes
    }
    return 0;
}

// --- Static Getters ---
quint64 MemoryInfo::total() const { return m_total; }
QString MemoryInfo::speed() const { return m_speed; }
QString MemoryInfo::slots() const { return m_slots; }
QString MemoryInfo::formFactor() const { return m_formFactor; }
QString MemoryInfo::type() const { return m_type; }
quint64 MemoryInfo::swapTotal() const { return m_swapTotal; }

// --- Dynamic Getters ---
quint64 MemoryInfo::inUse() const { return m_inUse; }
quint64 MemoryInfo::committed() const { return m_committed; }
quint64 MemoryInfo::cache() const { return m_cache; }
quint64 MemoryInfo::swapUsed() const { return m_swapUsed; }
QVariantList MemoryInfo::usageHistory() const { return m_usageHistory; }