import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Cutie
import Cutie.SysMonitor
import Cutie.Battery

CutiePage {
	id: batteryPage

	readonly property color cardColor: Qt.rgba(
		Atmosphere.secondaryAlphaColor.r,
		Atmosphere.secondaryAlphaColor.g,
		Atmosphere.secondaryAlphaColor.b,
		0.1
	)
	property int cardRadius: 16
	property int cardPadding: 20
	readonly property var chargeHistory: BatteryHistory.points.map(function(point) {
		return Number(point.value) / 100;
	})
	readonly property string remainingTime: {
		let seconds = BatteryHistory.stateString === "Charging"
			? BatteryHistory.timeToFull : BatteryHistory.timeToEmpty;
		if (seconds <= 0 || Math.abs(BatteryHistory.energyRate) < 0.01)
			return qsTr("Unavailable");
		let hours = Math.floor(seconds / 3600);
		let minutes = Math.floor((seconds % 3600) / 60);
		if (hours > 0)
			return qsTr("%1 h %2 min").arg(hours).arg(minutes);
		return qsTr("%1 min").arg(minutes);
	}

	Component.onCompleted: BatteryHistory.refresh()

	Flickable {
		anchors.fill: parent
		contentHeight: mainColumn.implicitHeight + 40
		clip: true

		Column {
			id: mainColumn
			width: parent.width
			spacing: 24

			CutiePageHeader {
				title: qsTr("Battery")
				width: parent.width
			}

			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: batteryCardLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: batteryCardLayout
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
							text: qsTr("Battery")
							font.bold: true
							font.pixelSize: 20
						}
						Item { Layout.fillWidth: true }
						CutieLabel {
							text: BatteryHistory.stateString
							font.pixelSize: 12
							font.bold: true
							opacity: 0.85
						}
					}

					ColumnLayout {
						Layout.fillWidth: true
						spacing: 4

						RowLayout {
							Layout.fillWidth: true
							CutieLabel { text: qsTr("Charge"); font.pixelSize: 11; opacity: 0.6 }
							Item { Layout.fillWidth: true }
							CutieLabel { text: "100%"; font.pixelSize: 11; opacity: 0.6 }
						}

						LineGraph {
							Layout.fillWidth: true
							Layout.preferredHeight: 140
							values: batteryPage.chargeHistory
							maxValue: 1.0
							lineColor: Atmosphere.textColor
						}

						RowLayout {
							Layout.fillWidth: true
							CutieLabel { text: qsTr("24 hours"); font.pixelSize: 11; opacity: 0.6 }
							Item { Layout.fillWidth: true }
							CutieLabel { text: "0"; font.pixelSize: 11; opacity: 0.6 }
						}
					}

					Item { Layout.preferredHeight: 8 }

					ColumnLayout {
						Layout.fillWidth: true
						spacing: 4

						SwipeView {
							id: batterySwipeView
							Layout.fillWidth: true
							Layout.preferredHeight: 188
							clip: true

							GridLayout {
								columns: 2
								columnSpacing: 18
								rowSpacing: 12

								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Percentage"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: Math.round(BatteryHistory.percentage) + "%"; font.pixelSize: 20; font.bold: true }
								}
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Energy"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: BatteryHistory.energy > 0 ? Number(BatteryHistory.energy).toFixed(1) + " Wh" : qsTr("Unavailable"); font.pixelSize: 20; font.bold: true }
								}
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Voltage"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: BatteryHistory.voltage > 0 ? Number(BatteryHistory.voltage).toFixed(1) + " V" : qsTr("Unavailable"); font.pixelSize: 20; font.bold: true }
								}
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("Power"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel {
										text: BatteryHistory.energyRate !== 0
											? (BatteryHistory.stateString === "Discharging" ? "−" : BatteryHistory.stateString === "Charging" ? "+" : "") + Number(Math.abs(BatteryHistory.energyRate)).toFixed(2) + " W"
											: qsTr("Unavailable")
										font.pixelSize: 20
										font.bold: true
									}
								}
								ColumnLayout {
									spacing: 2
									CutieLabel { text: qsTr("State"); font.pixelSize: 12; opacity: 0.65 }
									CutieLabel { text: BatteryHistory.stateString; font.pixelSize: 18; font.bold: true }
								}
								ColumnLayout {
									spacing: 2
									CutieLabel {
										text: BatteryHistory.stateString === "Charging" ? qsTr("Time to full") : qsTr("Time to empty")
										font.pixelSize: 12
										opacity: 0.65
									}
									CutieLabel { text: batteryPage.remainingTime; font.pixelSize: 18; font.bold: true }
								}
							}

							GridLayout {
								columns: 2
								columnSpacing: 8
								rowSpacing: 8

								CutieLabel { text: qsTr("Energy full:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.energyFull > 0 ? Number(BatteryHistory.energyFull).toFixed(1) + " Wh" : qsTr("Unavailable"); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Energy full (design):"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.energyFullDesign > 0 ? Number(BatteryHistory.energyFullDesign).toFixed(1) + " Wh" : qsTr("Unavailable"); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Charge start threshold:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.hasChargeStartThreshold ? BatteryHistory.chargeStartThreshold + "%" : qsTr("Unavailable"); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Charge end threshold:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.hasChargeEndThreshold ? BatteryHistory.chargeEndThreshold + "%" : qsTr("Unavailable"); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Technology:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.technology; font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Capacity:"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.capacity > 0 ? Math.round(BatteryHistory.capacity) + "%" : qsTr("Unavailable"); font.pixelSize: 12; font.bold: true }

								CutieLabel { text: qsTr("Voltage min (design):"); font.pixelSize: 12; opacity: 0.65 }
								CutieLabel { text: BatteryHistory.voltageMinDesign > 0 ? Number(BatteryHistory.voltageMinDesign).toFixed(1) + " V" : qsTr("Unavailable"); font.pixelSize: 12; font.bold: true }
							}
						}

						PageIndicator {
							count: batterySwipeView.count
							currentIndex: batterySwipeView.currentIndex
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}
			}

			Item { width: 1; height: 16 }
		}
	}
}
