import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

Item {
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

			Item { width: 1; height: 24 }

			// ── Overall CPU card ─────────────────────────────────────
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
							text: Math.round(SysMonitor.cpuUsage * 100) + "%"
							font.pixelSize: 16
							opacity: 0.8
						}
					}

					LineGraph {
						Layout.fillWidth: true
						Layout.preferredHeight: 140
						values: SysMonitor.cpuHistory
						maxValue: 1.0
						lineColor: Atmosphere.textColor
					}
				}
			}

			// ── Per-core card ────────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: coreLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius
				visible: SysMonitor.coreCount > 0

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
						text: qsTr("Cores") + " (" + SysMonitor.coreCount + ")"
						font.bold: true
						font.pixelSize: 16
					}

					GridLayout {
						Layout.fillWidth: true
						columns: 2
						columnSpacing: 16
						rowSpacing: 12

						Repeater {
							model: SysMonitor.perCoreUsage

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

			Item { width: 1; height: 24 }
		}
	}
}
