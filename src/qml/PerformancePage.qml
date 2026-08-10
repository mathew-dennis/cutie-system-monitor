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

			// ── CPU card ─────────────────────────────────────────────
			// Mirrors the Memory page's RAM card: title + % on one row,
			// a graph, then a one-line summary underneath.
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: cpuLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: cpuLayout
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
							text: qsTr("CPU")
							font.bold: true
							font.pixelSize: 16
							Layout.fillWidth: true
						}

						CutieLabel {
							text: Math.round(SysMonitor.cpu.utilization * 100) + "%"
							font.pixelSize: 16
							opacity: 0.8
						}
					}

					LineGraph {
						Layout.fillWidth: true
						Layout.preferredHeight: 140
						values: SysMonitor.cpu.history
						maxValue: 1.0
						lineColor: Atmosphere.textColor
					}

					CutieLabel {
						text: SysMonitor.cpu.name + qsTr(" · ") + SysMonitor.cpu.speed
						font.pixelSize: 13
						opacity: 0.7
						elide: Text.ElideRight
						Layout.fillWidth: true
					}
				}
			}

			// ── Details card ─────────────────────────────────────────
			// Mirrors the Memory page's Breakdown card: one stacked
			// column of label/value rows instead of a side-by-side grid.
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: detailsLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: detailsLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Details")
						font.bold: true
						font.pixelSize: 16
					}

					Repeater {
						model: [
							{ label: qsTr("Processes"), value: SysMonitor.cpu.processes },
							{ label: qsTr("Threads"), value: SysMonitor.cpu.threads },
							{ label: qsTr("Handles"), value: SysMonitor.cpu.handles },
							{ label: qsTr("Up time"), value: SysMonitor.cpu.uptime }
						]

						RowLayout {
							Layout.fillWidth: true
							CutieLabel {
								text: modelData.label
								font.pixelSize: 14
								Layout.fillWidth: true
							}
							CutieLabel {
								text: modelData.value
								font.pixelSize: 14
								opacity: 0.7
							}
						}
					}
				}
			}

			// ── Processor card ───────────────────────────────────────
			// Mirrors the Memory page's "Memory module" card: a single
			// 2-column grid, not two grids competing for width.
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: cpuModuleLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: cpuModuleLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 10

					CutieLabel {
						text: qsTr("Processor")
						font.bold: true
						font.pixelSize: 16
					}

					GridLayout {
						Layout.fillWidth: true
						columns: 2
						columnSpacing: 12
						rowSpacing: 6

						CutieLabel { text: qsTr("Base speed:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.cpu.baseSpeed; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("Cores:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.cpu.coreCount; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("L1 cache:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.cpu.l1Cache; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("L2 cache:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.cpu.l2Cache; font.pixelSize: 12; font.bold: true }

						CutieLabel { text: qsTr("L3 cache:"); font.pixelSize: 12; opacity: 0.65 }
						CutieLabel { text: SysMonitor.cpu.l3Cache; font.pixelSize: 12; font.bold: true }
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
