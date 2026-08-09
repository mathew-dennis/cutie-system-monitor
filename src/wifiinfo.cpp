#include "wifiinfo.h"
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QNetworkInterface>
#include <QProcess>
#include <QRegularExpression>

WifiInfo::WifiInfo(QObject *parent)
	: QObject(parent),
	  m_connectionType("Wireless"),
	  m_receiveSpeed(0),
	  m_sendSpeed(0),
	  m_totalReceived(0),
	  m_totalSent(0),
	  m_signalStrength(0),
	  m_prevRxBytes(0),
	  m_prevTxBytes(0)
{
	// Pre-fill graph history arrays with zeroes
	for (int i = 0; i < MAX_HISTORY_POINTS; ++i) {
		m_receiveHistory.append(0.0);
		m_sendHistory.append(0.0);
	}

	detectInterface();
	updateNetworkAddresses();
	updateWirelessDetails();

	m_timeTracker.start();

	// Setup polling timer (1 second interval)
	m_updateTimer = new QTimer(this);
	connect(m_updateTimer, &QTimer::timeout, this, &WifiInfo::updateWifiStats);
	m_updateTimer->start(1000);

	updateWifiStats();
}

void WifiInfo::detectInterface()
{
	// Auto-detect the primary wireless interface from /sys/class/net
	QDir netDir("/sys/class/net");
	QStringList interfaces = netDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

	for (const QString &iface : interfaces) {
		// Wireless interfaces on Linux typically start with "wl" or have a wireless folder
		if (iface.startsWith("wl") || QFile::exists(QString("/sys/class/net/%1/wireless").arg(iface))) {
			m_interfaceName = iface;
			break;
		}
	}

	if (m_interfaceName.isEmpty()) {
		m_interfaceName = "wlp0s20f3"; // Fallback interface name
	}

	// Try reading device driver/model name from sysfs
	QFile deviceNameFile(QString("/sys/class/net/%1/device/driver/module/drivers").arg(m_interfaceName));
	if (QFile::exists(QString("/sys/class/net/%1/device/vendor").arg(m_interfaceName))) {
		m_adapterName = "Wi-Fi Adapter (" + m_interfaceName + ")";
	} else {
		m_adapterName = "Wireless Network Adapter";
	}

	// Fetch Hardware MAC Address
	QFile macFile(QString("/sys/class/net/%1/address").arg(m_interfaceName));
	if (macFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		m_hardwareAddress = macFile.readAll().trimmed().toUpper();
		macFile.close();
	}
}

void WifiInfo::updateNetworkAddresses()
{
	QNetworkInterface iface = QNetworkInterface::interfaceFromName(m_interfaceName);
	if (!iface.isValid()) {
		m_ipv4Address = "N/A";
		m_ipv6Address = "N/A";
		return;
	}

	QString ipv4 = "N/A";
	QString ipv6 = "N/A";

	const QList<QNetworkAddressEntry> entries = iface.addressEntries();
	for (const QNetworkAddressEntry &entry : entries) {
		QHostAddress addr = entry.ip();
		if (addr.protocol() == QAbstractSocket::IPv4Protocol) {
			ipv4 = addr.toString();
		} else if (addr.protocol() == QAbstractSocket::IPv6Protocol && !addr.isLoopback()) {
			ipv6 = addr.toString();
		}
	}

	if (m_ipv4Address != ipv4 || m_ipv6Address != ipv6) {
		m_ipv4Address = ipv4;
		m_ipv6Address = ipv6;
		emit connectionInfoChanged();
	}
}

void WifiInfo::updateWirelessDetails()
{
	// Read signal level and link information from /proc/net/wireless
	QFile wirelessFile("/proc/net/wireless");
	if (wirelessFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		// procfs reports size() == 0, which makes atEnd() true immediately;
		// read everything up front instead of looping on atEnd().
		const QStringList lines = QString::fromUtf8(wirelessFile.readAll()).split('\n');
		for (const QString &line : lines) {
			if (line.contains(m_interfaceName)) {
				QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
				if (parts.size() >= 3) {
					// Part 2 is Quality / Link level (e.g., 70.)
					double linkQuality = parts[2].toDouble();
					m_signalStrength = qBound(0, static_cast<int>((linkQuality / 70.0) * 100.0), 100);
				}
			}
		}
		wirelessFile.close();
	}

	// Parse iw/iwconfig or iwlink fallback for SSID & Frequency
	QProcess process;
	process.start("iwgetid", QStringList() << m_interfaceName << "-r");
	if (process.waitForFinished(200) && process.exitCode() == 0) {
		m_ssid = process.readAllStandardOutput().trimmed();
	} else {
		m_ssid = "N/A";
	}

	QProcess freqProcess;
	freqProcess.start("iwgetid", QStringList() << m_interfaceName << "-f");
	if (freqProcess.waitForFinished(200) && freqProcess.exitCode() == 0) {
		double freqHz = freqProcess.readAllStandardOutput().trimmed().toDouble();
		if (freqHz > 0) {
			m_frequency = QString::number(freqHz / 1e9, 'f', 2) + " GHz";
		} else {
			m_frequency = "5.26 GHz"; // Fallback default
		}
	}

	emit connectionInfoChanged();
}

void WifiInfo::updateWifiStats()
{
	quint64 currentRx = readSysfsValue(QString("/sys/class/net/%1/statistics/rx_bytes").arg(m_interfaceName));
	quint64 currentTx = readSysfsValue(QString("/sys/class/net/%1/statistics/tx_bytes").arg(m_interfaceName));

	qint64 elapsedMs = m_timeTracker.restart();
	if (elapsedMs <= 0) elapsedMs = 1000;

	m_totalReceived = currentRx;
	m_totalSent = currentTx;

	if (m_prevRxBytes > 0 && currentRx >= m_prevRxBytes) {
		m_receiveSpeed = ((currentRx - m_prevRxBytes) * 1000) / elapsedMs; // Bytes/sec
	} else {
		m_receiveSpeed = 0;
	}

	if (m_prevTxBytes > 0 && currentTx >= m_prevTxBytes) {
		m_sendSpeed = ((currentTx - m_prevTxBytes) * 1000) / elapsedMs; // Bytes/sec
	} else {
		m_sendSpeed = 0;
	}

	m_prevRxBytes = currentRx;
	m_prevTxBytes = currentTx;

	// Update Graph History Buffer
	m_receiveHistory.removeFirst();
	m_sendHistory.removeFirst();
	m_receiveHistory.append(static_cast<double>(m_receiveSpeed));
	m_sendHistory.append(static_cast<double>(m_sendSpeed));

	// Update IP and Signal
	updateNetworkAddresses();
	updateWirelessDetails();

	emit statsChanged();
	emit historyChanged();
}

quint64 WifiInfo::readSysfsValue(const QString &filename) const
{
	QFile file(filename);
	if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
		quint64 val = file.readAll().trimmed().toULongLong();
		file.close();
		return val;
	}
	return 0;
}

// --- Getters ---
QString WifiInfo::adapterName() const { return m_adapterName; }
QString WifiInfo::interfaceName() const { return m_interfaceName; }
QString WifiInfo::connectionType() const { return m_connectionType; }
QString WifiInfo::ssid() const { return m_ssid; }
QString WifiInfo::frequency() const { return m_frequency; }
QString WifiInfo::hardwareAddress() const { return m_hardwareAddress; }
QString WifiInfo::ipv4Address() const { return m_ipv4Address; }
QString WifiInfo::ipv6Address() const { return m_ipv6Address; }

quint64 WifiInfo::receiveSpeed() const { return m_receiveSpeed; }
quint64 WifiInfo::sendSpeed() const { return m_sendSpeed; }
quint64 WifiInfo::totalReceived() const { return m_totalReceived; }
quint64 WifiInfo::totalSent() const { return m_totalSent; }
int WifiInfo::signalStrength() const { return m_signalStrength; }

QVariantList WifiInfo::receiveHistory() const { return m_receiveHistory; }
QVariantList WifiInfo::sendHistory() const { return m_sendHistory; }
