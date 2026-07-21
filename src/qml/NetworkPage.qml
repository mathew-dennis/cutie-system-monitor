import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

Item {
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

			Item { width: 1; height: 24 }

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

					CutieLabel {
						text: qsTr("Network")
						font.bold: true
						font.pixelSize: 16
					}

					RowLayout {
						Layout.fillWidth: true
						spacing: 20

						RowLayout {
							spacing: 6
							Rectangle { width: 10; height: 10; radius: 5; color: Atmosphere.textColor }
							CutieLabel {
								text: qsTr("Down: %1").arg(SysMonitor.formatRate(SysMonitor.totalRxRate))
								font.pixelSize: 13
								opacity: 0.8
							}
						}

						RowLayout {
							spacing: 6
							Rectangle { width: 10; height: 10; radius: 5; color: Atmosphere.primaryColor }
							CutieLabel {
								text: qsTr("Up: %1").arg(SysMonitor.formatRate(SysMonitor.totalTxRate))
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
							values: SysMonitor.netRxHistory
							lineColor: Atmosphere.textColor
							fillOpacity: 0.15
						}

						LineGraph {
							anchors.fill: parent
							values: SysMonitor.netTxHistory
							lineColor: Atmosphere.primaryColor
							fillOpacity: 0.08
						}
					}

					RowLayout {
						Layout.fillWidth: true
						CutieLabel {
							text: qsTr("Total received: %1").arg(SysMonitor.formatBytes(SysMonitor.totalRxBytes))
							font.pixelSize: 12
							opacity: 0.6
							Layout.fillWidth: true
						}
					}
					RowLayout {
						Layout.fillWidth: true
						CutieLabel {
							text: qsTr("Total sent: %1").arg(SysMonitor.formatBytes(SysMonitor.totalTxBytes))
							font.pixelSize: 12
							opacity: 0.6
							Layout.fillWidth: true
						}
					}
				}
			}

			// ── Interfaces card ──────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: ifaceLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: ifaceLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Interfaces")
						font.bold: true
						font.pixelSize: 16
					}

					CutieLabel {
						visible: SysMonitor.networkInterfaces.length === 0
						text: qsTr("No active interfaces")
						font.pixelSize: 13
						opacity: 0.6
					}

					Repeater {
						model: SysMonitor.networkInterfaces

						ColumnLayout {
							Layout.fillWidth: true
							spacing: 6

							RowLayout {
								Layout.fillWidth: true
								CutieLabel {
									text: modelData.name
									font.pixelSize: 14
									font.bold: true
									Layout.fillWidth: true
								}
							}

							RowLayout {
								Layout.fillWidth: true
								CutieLabel {
									text: qsTr("↓ %1").arg(SysMonitor.formatRate(modelData.rxRate))
									font.pixelSize: 12
									opacity: 0.7
									Layout.fillWidth: true
								}
								CutieLabel {
									text: qsTr("↑ %1").arg(SysMonitor.formatRate(modelData.txRate))
									font.pixelSize: 12
									opacity: 0.7
								}
							}

							Rectangle {
								Layout.fillWidth: true
								height: 1
								color: Atmosphere.secondaryAlphaColor
								opacity: 0.2
								visible: index < SysMonitor.networkInterfaces.length - 1
							}
						}
					}
				}
			}

			Item { width: 1; height: 24 }
		}
	}
}
