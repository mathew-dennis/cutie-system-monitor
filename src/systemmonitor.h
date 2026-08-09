#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QString>

#include "cpuinfo.h"
#include "meminfo.h"
#include "wifiinfo.h"

// ============================================================================
// SYSTEM MONITOR - composition root tying the three independent modules
// (CpuInfo, MemoryInfo, WifiInfo) together and exposing them to QML.
// ============================================================================

class SystemMonitor : public QObject
{
	Q_OBJECT

	// Sub-module property objects (access via cpu.*, memory.*, network.*)
	Q_PROPERTY(CpuInfo* cpu READ cpu CONSTANT)
	Q_PROPERTY(MemoryInfo* memory READ memory CONSTANT)
	Q_PROPERTY(WifiInfo* network READ network CONSTANT)

public:
	explicit SystemMonitor(QObject *parent = nullptr);

	CpuInfo* cpu() { return &m_cpu; }
	MemoryInfo* memory() { return &m_memory; }
	WifiInfo* network() { return &m_network; }

	// Shared formatting helpers used by QML pages
	Q_INVOKABLE QString formatBytes(quint64 bytes) const;
	Q_INVOKABLE QString formatRate(quint64 bytesPerSec) const;

private slots:
	void poll();

private:
	static QVariantList pushHistory(QVariantList history, double value, int maxLen);

	static constexpr int kHistoryLength = 60;

	QTimer m_timer;
	int m_intervalMs = 1000;

	// Sub-module instances. Memory and Network poll themselves on their
	// own internal QTimers, so only CPU needs driving from m_timer.
	CpuInfo m_cpu;
	MemoryInfo m_memory;
	WifiInfo m_network;
};
