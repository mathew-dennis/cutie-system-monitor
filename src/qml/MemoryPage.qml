import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

CutiePage {
	id: memPage

	readonly property color cardColor: Qt.rgba(
		Atmosphere.secondaryAlphaColor.r,
		Atmosphere.secondaryAlphaColor.g,
		Atmosphere.secondaryAlphaColor.b,
		0.1
	)
	property int cardRadius: 16
	property int cardPadding: 20

	readonly property real usedFraction: SysMonitor.memory.total > 0
		? SysMonitor.memory.inUse / SysMonitor.memory.total : 0
	readonly property real swapFraction: SysMonitor.memory.swapTotal > 0
		? SysMonitor.memory.swapUsed / SysMonitor.memory.swapTotal : 0

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
				title: qsTr("Memory")
				width: parent.width
			}

			// ── Memory Card ───────────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: memCardLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: memCardLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 10

					// --- 1. Header ---
					RowLayout {
						Layout.fillWidth: true

						CutieLabel {
							text: qsTr("Memory")
							font.bold: true
							font.pixelSize: 20
						}

						Item { Layout.fillWidth: true }

						CutieLabel {
							text: Math.round(memPage.usedFraction * 100) + "%"
							font.pixelSize: 12
							font.bold: true
							opacity: 0.85
						}
					}

					// --- 2. Graph Container ---
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
							values: SysMonitor.memory.usageHistory
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

					// --- 3. Swipeable Stats Pages ---
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 4

						SwipeView {
							id: statsSwipeView
							Layout.fillWidth: true
							Layout.preferredHeight: 170
							clip: true

							// Page 1: Dynamic Metrics Layout
							GridLayout {
								columns: 2
								columnSpacing: 12
								rowSpacing: 14
								Layout.fillWidth: true

								// In use
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("In use"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.memory.inUse); font.pixelSize: 18; font.bold: true }
								}

								// Available
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Available"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.memory.total - SysMonitor.memory.inUse); font.pixelSize: 18; font.bold: true }
								}

								// Committed
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Committed"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.memory.committed); font.pixelSize: 18; font.bold: true }
								}

								// Cached
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Cached"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.memory.cache); font.pixelSize: 18; font.bold: true }
								}

								// Swap used
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Swap used"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.memory.swapUsed); font.pixelSize: 18; font.bold: true }
								}

								// Swap available
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Swap available"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: SysMonitor.formatBytes(SysMonitor.memory.swapTotal - SysMonitor.memory.swapUsed); font.pixelSize: 18; font.bold: true }
								}
							}

							// Page 2: Static Memory Module Info
							GridLayout {
								columns: 2
								columnSpacing: 12
								rowSpacing: 10
								Layout.fillWidth: true

								CutieLabel { text: qsTr("Speed:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.memory.speed; font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Slots used:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.memory.slotsInUse; font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Form factor:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.memory.formFactor; font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Type:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: SysMonitor.memory.type; font.pixelSize: 12; font.bold: true }
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

			// ── Swap Card ────────────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: swapLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius
				visible: SysMonitor.memory.swapTotal > 0

				ColumnLayout {
					id: swapLayout
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
							text: qsTr("Swap")
							font.bold: true
							font.pixelSize: 16
							Layout.fillWidth: true
						}
						CutieLabel {
							text: Math.round(memPage.swapFraction * 100) + "%"
							font.pixelSize: 16
							opacity: 0.8
						}
					}

					Rectangle {
						Layout.fillWidth: true
						height: 8
						radius: 4
						color: Atmosphere.primaryAlphaColor

						Rectangle {
							height: parent.height
							width: parent.width * memPage.swapFraction
							radius: 4
							color: Atmosphere.textColor

							Behavior on width {
								NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
							}
						}
					}

					CutieLabel {
						text: qsTr("%1 of %2 used")
							.arg(SysMonitor.formatBytes(SysMonitor.memory.swapUsed))
							.arg(SysMonitor.formatBytes(SysMonitor.memory.swapTotal))
						font.pixelSize: 13
						opacity: 0.7
					}
				}
			}

			Item { width: 1; height: 16 }
		}
	}
}
