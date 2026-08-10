import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

CutiePage {
	id: perfPage

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
				title: qsTr("Performance")
				width: parent.width
			}

			// ── Performance Card─────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: cpuCardLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: cpuCardLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 10

					// --- 1. Header: "CPU" + Model Name ---
					RowLayout {
						Layout.fillWidth: true
							spacing: 12

							CutieLabel {
								text: qsTr("CPU")
								font.bold: true
								font.pixelSize: 20
								Layout.alignment: Qt.AlignTop
							}

							CutieLabel {
								text: SysMonitor.cpu.name
								font.pixelSize: 12
								font.bold: true
								opacity: 0.85
								Layout.fillWidth: true
								Layout.maximumWidth: Math.max(0, parent.width - cpuTitleLabel.implicitWidth - 12)
								wrapMode: Text.WordWrap
								maximumLineCount: 2
								Layout.alignment: Qt.AlignTop

					// --- 2. Graph Container with Text Overlay Labels ---
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 4

						RowLayout {
							Layout.fillWidth: true
							CutieLabel {
								text: "% Utilization"
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
							values: SysMonitor.cpu.history
							maxValue: 1.0
							lineColor: Atmosphere.textColor
						}

						RowLayout {
							Layout.fillWidth: true
							CutieLabel {
								text: "60 seconds"
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

					// --- 3. Stats Grid ---
					RowLayout {
						Layout.fillWidth: true
						spacing: 24

						// Left Side: Live Dynamic Metrics
						GridLayout {
							columns: 2
							columnSpacing: 24
							rowSpacing: 14
							Layout.alignment: Qt.AlignTop

							// Utilization
							ColumnLayout {
								spacing: 2
								CutieLabel {
									text: qsTr("Utilization")
									font.pixelSize: 12
									opacity: 0.65
								}
								CutieLabel {
									text: Math.round(SysMonitor.cpu.utilization * 100) + "%"
									font.pixelSize: 20
									font.bold: true
								}
							}

							// Speed
							ColumnLayout {
								spacing: 2
								CutieLabel {
									text: qsTr("Speed")
									font.pixelSize: 12
									opacity: 0.65
								}
								CutieLabel {
									text: SysMonitor.cpu.speed
									font.pixelSize: 20
									font.bold: true
								}
							}

							// Processes
							ColumnLayout {
								spacing: 2
								CutieLabel {
									text: qsTr("Processes")
									font.pixelSize: 12
									opacity: 0.65
								}
								CutieLabel {
									text: SysMonitor.cpu.processes
									font.pixelSize: 18
									font.bold: true
								}
							}

							// Threads
							ColumnLayout {
								spacing: 2
								CutieLabel {
									text: qsTr("Threads")
									font.pixelSize: 12
									opacity: 0.65
								}
								CutieLabel {
									text: SysMonitor.cpu.threads
									font.pixelSize: 18
									font.bold: true
								}
							}

							// Handles
							ColumnLayout {
								spacing: 2
								CutieLabel {
									text: qsTr("Handles")
									font.pixelSize: 12
									opacity: 0.65
								}
								CutieLabel {
									text: SysMonitor.cpu.handles
									font.pixelSize: 18
									font.bold: true
								}
							}

							// Up time
							ColumnLayout {
								spacing: 2
								CutieLabel {
									text: qsTr("Up time")
									font.pixelSize: 12
									opacity: 0.65
								}
								CutieLabel {
									text: SysMonitor.cpu.uptime
									font.pixelSize: 18
									font.bold: true
								}
							}
						}

						Item { Layout.fillWidth: true }

						// Right Side: Static Hardware Info & Caches
						GridLayout {
							columns: 2
							columnSpacing: 12
							rowSpacing: 6
							Layout.alignment: Qt.AlignTop

							// Base speed
							CutieLabel { text: qsTr("Base speed:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: SysMonitor.cpu.baseSpeed; font.pixelSize: 12; font.bold: true }

							// Sockets
							CutieLabel { text: qsTr("Sockets:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: "1"; font.pixelSize: 12; font.bold: true }

							// Cores
							CutieLabel { text: qsTr("Cores:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: SysMonitor.cpu.coreCount; font.pixelSize: 12; font.bold: true }

							// Logical Processors
							CutieLabel { text: qsTr("Logical processors:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: SysMonitor.cpu.coreCount; font.pixelSize: 12; font.bold: true }

							// Virtualization
							CutieLabel { text: qsTr("Virtualization:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: qsTr("Enabled"); font.pixelSize: 12; font.bold: true }

							// L1 cache
							CutieLabel { text: qsTr("L1 cache:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: SysMonitor.cpu.l1Cache; font.pixelSize: 12; font.bold: true }

							// L2 cache
							CutieLabel { text: qsTr("L2 cache:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: SysMonitor.cpu.l2Cache; font.pixelSize: 12; font.bold: true }

							// L3 cache
							CutieLabel { text: qsTr("L3 cache:"); font.pixelSize: 12; opacity: 0.65 }
							CutieLabel { text: SysMonitor.cpu.l3Cache; font.pixelSize: 12; font.bold: true }
						}
					}
				}
			}

			// ── Per-core Usage Section ───────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: coreLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius
				visible: SysMonitor.cpu.coreCount > 0

				ColumnLayout {
					id: coreLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Core Utilization") + " (" + SysMonitor.cpu.coreCount + " Cores)"
						font.bold: true
						font.pixelSize: 16
					}

					GridLayout {
						Layout.fillWidth: true
						columns: 2
						columnSpacing: 16
						rowSpacing: 12

						Repeater {
							model: SysMonitor.cpu.perCoreUsage

							ColumnLayout {
								Layout.fillWidth: true
								spacing: 4

								RowLayout {
									Layout.fillWidth: true
									CutieLabel {
										text: qsTr("Core %1").arg(index)
										font.pixelSize: 12
										opacity: 0.7
										Layout.fillWidth: true
									}
									CutieLabel {
										text: Math.round(modelData * 100) + "%"
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
										width: parent.width * modelData
										radius: 3
										color: Atmosphere.textColor

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