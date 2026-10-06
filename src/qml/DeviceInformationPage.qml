import QtQuick
import QtQuick.Layouts
import Cutie

CutiePage {
	id: deviceInformationPage

	property var systemInfo
	readonly property color cardColor: Qt.rgba(
		Atmosphere.secondaryAlphaColor.r,
		Atmosphere.secondaryAlphaColor.g,
		Atmosphere.secondaryAlphaColor.b,
		0.1
	)
	property int cardRadius: 16
	property int cardPadding: 20

	CutiePageHeader {
		id: header
		title: qsTr("Device Information")
		width: parent.width
	}

	Flickable {
		anchors {
			top: header.bottom
			bottom: parent.bottom
			left: parent.left
			right: parent.right
		}
		contentHeight: mainColumn.implicitHeight + 40
		clip: true

		Column {
			id: mainColumn
			width: parent.width
			spacing: 0

			Item { width: 1; height: 20 }

			Image {
				width: height * sourceSize.width / sourceSize.height
				height: (parent.width - 80) / 3
				anchors.horizontalCenter: parent.horizontalCenter
				source: "image://icon/cutie-shell"
			}

			Item { width: 1; height: 10 }

			CutieLabel {
				text: qsTr("Cutie Shell")
				font.pixelSize: 20
				font.bold: true
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Item { width: 1; height: 32 }

			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: softwareLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: softwareLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Software Information")
						font.bold: true
						font.pixelSize: 16
					}

					ColumnLayout {
						Layout.fillWidth: true
						spacing: 10

						InfoRow { label: qsTr("Shell Name"); value: qsTr("Cutie Shell") }
						InfoRow { label: qsTr("OS Name"); value: deviceInformationPage.systemInfo.osInfo.osName }
						InfoRow { label: qsTr("Kernel Version"); value: deviceInformationPage.systemInfo.osInfo.kernel }
						InfoRow { label: qsTr("Build Version"); value: deviceInformationPage.systemInfo.osInfo.build }
						InfoRow { label: qsTr("Update Channel"); value: deviceInformationPage.systemInfo.osInfo.channel }
					}
				}
			}

			Item { width: 1; height: 24 }

			Rectangle {
				width: parent.width - 32
				anchors.horizontalCenter: parent.horizontalCenter
				height: hardwareLayout.implicitHeight + cardPadding * 2
				color: cardColor
				radius: cardRadius

				ColumnLayout {
					id: hardwareLayout
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: cardPadding
					}
					spacing: 14

					CutieLabel {
						text: qsTr("Hardware Information")
						font.bold: true
						font.pixelSize: 16
					}

					ColumnLayout {
						Layout.fillWidth: true
						spacing: 10

						InfoRow { label: qsTr("Device Model"); value: deviceInformationPage.systemInfo.hwInfo.device }
						InfoRow { label: qsTr("Processor"); value: deviceInformationPage.systemInfo.hwInfo.processor }
						InfoRow { label: qsTr("Memory"); value: deviceInformationPage.systemInfo.hwInfo.memory }
						InfoRow { label: qsTr("Storage"); value: deviceInformationPage.systemInfo.hwInfo.storage }
						InfoRow { label: qsTr("Display"); value: deviceInformationPage.systemInfo.hwInfo.display }
						InfoRow { label: qsTr("Battery Status"); value: deviceInformationPage.systemInfo.hwInfo.battery }
					}
				}
			}

			Item { width: 1; height: 24 }
		}
	}

	component InfoRow: RowLayout {
		id: rowRoot
		property string label: ""
		property string value: ""

		Layout.fillWidth: true
		spacing: 12

		CutieLabel {
			text: rowRoot.label
			font.pixelSize: 14
			opacity: 0.9
			Layout.preferredWidth: parent.width * 0.35
			elide: Text.ElideRight
		}

		CutieLabel {
			text: rowRoot.value
			font.pixelSize: 14
			font.bold: true
			Layout.fillWidth: true
			horizontalAlignment: Text.AlignRight
			elide: Text.ElideRight
			maximumLineCount: 1
		}
	}
}
