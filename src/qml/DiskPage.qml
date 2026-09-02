import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

CutiePage {
	id: diskPage

	readonly property color cardColor: Qt.rgba(
		Atmosphere.secondaryAlphaColor.r,
		Atmosphere.secondaryAlphaColor.g,
		Atmosphere.secondaryAlphaColor.b,
		0.1
	)
	property int cardRadius: 16
	property int cardPadding: 20

	Flickable {
		id: pageFlickable
		anchors.fill: parent
		contentHeight: mainColumn.height + 40
		clip: true

		Column {
			id: mainColumn
			width: parent.width
			spacing: 24

			CutiePageHeader {
				title: qsTr("Disk")
				width: parent.width
			}

			// ── Disk Card ────────────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: diskCardLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: diskCardLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 10

					// --- 1. Header: "Disk" + Model Name ---
					RowLayout {
						Layout.fillWidth: true
						spacing: 16

						CutieLabel {
							text: qsTr("Disk")
							font.bold: true
							font.pixelSize: 20
							Layout.alignment: Qt.AlignTop
						}

						CutieLabel {
							text: SysMonitor.disk.model
							font.pixelSize: 12
							font.bold: true
							opacity: 0.85
							wrapMode: Text.WordWrap
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignTop
							horizontalAlignment: Text.AlignRight
						}
					}

					// --- 2. Graph Container with Text Overlay Labels ---
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 4

						RowLayout {
							Layout.fillWidth: true
							CutieLabel {
								text: qsTr("Active time")
								font.pixelSize: 11
								opacity: 0.6
							}
							Item { Layout.fillWidth: true }
							CutieLabel {
								text: "100%"
								font.pixelSize: 11
								opacity: 0.6
							}
						}

						LineGraph {
							Layout.fillWidth: true
							Layout.preferredHeight: 140
							values: SysMonitor.disk.activeTimeHistory
							maxValue: 1.0
							lineColor: Atmosphere.textColor
						}

						RowLayout {
							Layout.fillWidth: true
							CutieLabel {
								text: qsTr("60 seconds")
								font.pixelSize: 11
								opacity: 0.6
							}
							Item { Layout.fillWidth: true }
							CutieLabel {
								text: "0"
								font.pixelSize: 11
								opacity: 0.6
							}
						}
					}

					Item { Layout.preferredHeight: 8 }

					// --- 3. Swipeable Stats Pages ---
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 4

						SwipeView {
							id: statsSwipeView
							Layout.fillWidth: true
							Layout.preferredHeight: 170
							clip: true

							// Page 1: Live Dynamic Metrics
							GridLayout {
								columns: 2
								columnSpacing: 18
								rowSpacing: 12
								Layout.fillWidth: true

								// Active time
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Active time"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: Math.round(SysMonitor.disk.activeTime * 100) + "%"; font.pixelSize: 20; font.bold: true }
								}

								// Average response time
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Avg. response time"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.disk.averageResponseTime.toFixed(1) + " ms"; font.pixelSize: 20; font.bold: true }
								}

								// Read speed
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Read speed"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatRate(SysMonitor.disk.readSpeed); font.pixelSize: 18; font.bold: true }
								}

								// Write speed
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Write speed"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatRate(SysMonitor.disk.writeSpeed); font.pixelSize: 18; font.bold: true }
								}

								// Total read
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Total read"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.disk.totalRead); font.pixelSize: 18; font.bold: true }
								}

								// Total written
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Total written"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.disk.totalWritten); font.pixelSize: 18; font.bold: true }
								}
							}

							// Page 2: Static Hardware Info
							GridLayout {
								columns: 2
								columnSpacing: 8
								rowSpacing: 6
								Layout.fillWidth: true

								CutieLabel { text: qsTr("Capacity:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.formatBytes(SysMonitor.disk.capacity); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("System disk:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.disk.isSystemDisk ? qsTr("Yes") : qsTr("No"); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Type:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.disk.type; font.pixelSize: 12; font.bold: true }
							}
						}

						// Page Indicator Dots
						PageIndicator {
							id: pageIndicator
							count: statsSwipeView.count
							currentIndex: statsSwipeView.currentIndex
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}
			}

			// ── Transfer Rate Section ────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: rateLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: rateLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Transfer Rate")
						font.bold: true
						font.pixelSize: 16
					}

					GridLayout {
						Layout.fillWidth: true
						columns: 2
						columnSpacing: 10
						rowSpacing: 12

						Repeater {
							model: 2

							ColumnLayout {
								id: rateDelegate
								Layout.fillWidth: true
								spacing: 4

								readonly property bool isRead: index === 0
								readonly property string rateLabel: isRead ? qsTr("Read") : qsTr("Write")
								readonly property real speedValue: isRead ? SysMonitor.disk.readSpeed : SysMonitor.disk.writeSpeed
								readonly property real fraction: SysMonitor.disk.peakSpeed > 0
									? speedValue / SysMonitor.disk.peakSpeed : 0

								RowLayout {
									Layout.fillWidth: true
									CutieLabel {
										text: rateDelegate.rateLabel
										font.pixelSize: 12
										opacity: 0.7
										Layout.fillWidth: true
									}
									CutieLabel {
										text: SysMonitor.formatRate(rateDelegate.speedValue)
										font.pixelSize: 12
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
										width: parent.width * rateDelegate.fraction
										radius: 3
										color: rateDelegate.isRead ? Atmosphere.textColor : Atmosphere.primaryColor

										Behavior on width {
											NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
										}
									}
								}
							}
						}
					}
				}
			}

			Item { width: 1; height: 16 }
		}
	}
}
