import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

CutiePage {
	id: netPage

	readonly property color cardColor: Qt.rgba(
		Atmosphere.secondaryAlphaColor.r,
		Atmosphere.secondaryAlphaColor.g,
		Atmosphere.secondaryAlphaColor.b,
		0.1
	)
	property int cardRadius: 16
	property int cardPadding: 20

	Flickable {
		anchors.fill: parent
		contentHeight: mainColumn.height + 40
		clip: true

		Column {
			id: mainColumn
			width: parent.width
			spacing: 24

			CutiePageHeader {
				title: qsTr("Network")
				width: parent.width
			}

			// ── Throughput card ──────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: throughputLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: throughputLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 10

					RowLayout {
						Layout.fillWidth: true

						CutieLabel {
							text: qsTr("Network")
							font.bold: true
							font.pixelSize: 16
							Layout.fillWidth: true
						}

						CutieLabel {
							text: SysMonitor.network.ssid
							font.pixelSize: 13
							opacity: 0.7
							elide: Text.ElideRight
						}
					}

					RowLayout {
						Layout.fillWidth: true
						spacing: 20

						RowLayout {
							spacing: 6
							Rectangle { width: 10; height: 10; radius: 5; color: Atmosphere.textColor }
							CutieLabel {
								text: qsTr("Down: %1").arg(SysMonitor.formatRate(SysMonitor.network.receiveSpeed))
								font.pixelSize: 13
								opacity: 0.8
							}
						}

						RowLayout {
							spacing: 6
							Rectangle { width: 10; height: 10; radius: 5; color: Atmosphere.primaryColor }
							CutieLabel {
								text: qsTr("Up: %1").arg(SysMonitor.formatRate(SysMonitor.network.sendSpeed))
								font.pixelSize: 13
								opacity: 0.8
							}
						}
					}

					Item {
						Layout.fillWidth: true
						Layout.preferredHeight: 140

						LineGraph {
							anchors.fill: parent
							values: SysMonitor.network.receiveHistory
							lineColor: Atmosphere.textColor
							fillOpacity: 0.15
						}

						LineGraph {
							anchors.fill: parent
							values: SysMonitor.network.sendHistory
							lineColor: Atmosphere.primaryColor
							fillOpacity: 0.08
						}
					}

					RowLayout {
						Layout.fillWidth: true
						CutieLabel {
							text: qsTr("Total received: %1").arg(SysMonitor.formatBytes(SysMonitor.network.totalReceived))
							font.pixelSize: 12
							opacity: 0.6
							Layout.fillWidth: true
						}
					}
					RowLayout {
						Layout.fillWidth: true
						CutieLabel {
							text: qsTr("Total sent: %1").arg(SysMonitor.formatBytes(SysMonitor.network.totalSent))
							font.pixelSize: 12
							opacity: 0.6
							Layout.fillWidth: true
						}
					}
				}
			}

			// ── Connection card ──────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: connLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: connLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					RowLayout {
						Layout.fillWidth: true
						CutieLabel {
							text: qsTr("Connection")
							font.bold: true
							font.pixelSize: 16
							Layout.fillWidth: true
						}
						CutieLabel {
							text: qsTr("Signal: %1%").arg(SysMonitor.network.signalStrength)
							font.pixelSize: 13
							opacity: 0.7
						}
					}

					Rectangle {
						Layout.fillWidth: true
						height: 6
						radius: 3
						color: Atmosphere.primaryAlphaColor

						Rectangle {
							height: parent.height
							width: parent.width * (SysMonitor.network.signalStrength / 100)
							radius: 3
							color: Atmosphere.textColor

							Behavior on width {
								NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
							}
						}
					}

					GridLayout {
						Layout.fillWidth: true
						columns: 2
						columnSpacing: 12
						rowSpacing: 6

						CutieLabel { text: qsTr("Adapter:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel {
							text: SysMonitor.network.adapterName
							font.pixelSize: 12
							font.bold: true
							elide: Text.ElideRight
							Layout.fillWidth: true
						}

						CutieLabel { text: qsTr("Interface:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.network.interfaceName; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("Type:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.network.connectionType; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("Frequency:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.network.frequency; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("IPv4 address:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.network.ipv4Address; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("IPv6 address:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel {
							text: SysMonitor.network.ipv6Address
							font.pixelSize: 12
							font.bold: true
							elide: Text.ElideRight
							Layout.fillWidth: true
						}

						CutieLabel { text: qsTr("MAC address:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.network.hardwareAddress; font.pixelSize: 12; font.bold: true }
					}
				}
			}

			Item { width: 1; height: 24 }
		}
	}
}
