import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor

Item {
	id: memPage

	readonly property color cardColor: Qt.rgba(
		Atmosphere.secondaryAlphaColor.r,
		Atmosphere.secondaryAlphaColor.g,
		Atmosphere.secondaryAlphaColor.b,
		0.1
	)
	property int cardRadius: 16
	property int cardPadding: 20

	readonly property real usedFraction: SysMonitor.memTotal > 0
		? SysMonitor.memUsed / SysMonitor.memTotal : 0
	readonly property real swapFraction: SysMonitor.swapTotal > 0
		? SysMonitor.swapUsed / SysMonitor.swapTotal : 0

	Flickable {
		anchors.fill: parent
		contentHeight: mainColumn.height + 40
		clip: true

		Column {
			id: mainColumn
			width: parent.width
			spacing: 24

			Item { width: 1; height: 24 }

			// ── RAM card ─────────────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: ramLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: ramLayout
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
							text: qsTr("Memory")
							font.bold: true
							font.pixelSize: 16
							Layout.fillWidth: true
						}

						CutieLabel {
							text: Math.round(memPage.usedFraction * 100) + "%"
							font.pixelSize: 16
							opacity: 0.8
						}
					}

					LineGraph {
						Layout.fillWidth: true
						Layout.preferredHeight: 140
						values: SysMonitor.memHistory
						maxValue: 1.0
						lineColor: Atmosphere.textColor
					}

					CutieLabel {
						text: qsTr("%1 of %2 used")
							.arg(SysMonitor.formatBytes(SysMonitor.memUsed))
							.arg(SysMonitor.formatBytes(SysMonitor.memTotal))
						font.pixelSize: 13
						opacity: 0.7
					}
				}
			}

			// ── Breakdown card ───────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: breakdownLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: breakdownLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Breakdown")
						font.bold: true
						font.pixelSize: 16
					}

					Repeater {
						model: [
							{ label: qsTr("Used"), value: SysMonitor.memUsed },
							{ label: qsTr("Cached"), value: SysMonitor.memCached },
							{ label: qsTr("Buffers"), value: SysMonitor.memBuffers },
							{ label: qsTr("Available"), value: SysMonitor.memAvailable }
						]

						RowLayout {
							Layout.fillWidth: true
							CutieLabel {
								text: modelData.label
								font.pixelSize: 14
								Layout.fillWidth: true
							}
							CutieLabel {
								text: SysMonitor.formatBytes(modelData.value)
								font.pixelSize: 14
								opacity: 0.7
							}
						}
					}
				}
			}

			// ── Swap card ────────────────────────────────────────────
			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: swapLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius
				visible: SysMonitor.swapTotal > 0

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
							.arg(SysMonitor.formatBytes(SysMonitor.swapUsed))
							.arg(SysMonitor.formatBytes(SysMonitor.swapTotal))
						font.pixelSize: 13
						opacity: 0.7
					}
				}
			}

			Item { width: 1; height: 24 }
		}
	}
}
