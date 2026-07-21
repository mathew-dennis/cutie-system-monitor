import Cutie
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

CutieWindow {
	id: mainWindow
	width: 400
	height: 800
	visible: true
	title: qsTr("System Monitor")

	property var tabs: [
		{ text: qsTr("Performance"), icon: "utilities-system-monitor-symbolic" },
		{ text: qsTr("Memory"), icon: "drive-harddisk-symbolic" },
		{ text: qsTr("Network"), icon: "network-transmit-receive-symbolic" }
	]

	initialPage: CutiePage {
		id: rootPage
		width: mainWindow.width
		height: mainWindow.height

		ColumnLayout {
			anchors.fill: parent
			spacing: 0

			CutiePageHeader {
				title: mainWindow.title
				Layout.fillWidth: true
			}

			Row {
				id: tabBar
				Layout.fillWidth: true
				Layout.leftMargin: 16
				Layout.rightMargin: 16
				Layout.bottomMargin: 10
				spacing: 8

				Repeater {
					model: mainWindow.tabs
					CutieButton {
						text: mainWindow.tabs[index]["text"]
						icon.name: mainWindow.tabs[index]["icon"]
						icon.color: Atmosphere.textColor
						checkable: true
						checked: pageStackLayout.currentIndex === index
						autoExclusive: true
						width: (tabBar.width - tabBar.spacing * (mainWindow.tabs.length - 1)) / mainWindow.tabs.length

						onClicked: pageStackLayout.currentIndex = index
					}
				}
			}

			StackLayout {
				id: pageStackLayout
				Layout.fillWidth: true
				Layout.fillHeight: true
				currentIndex: 0

				PerformancePage { }
				MemoryPage { }
				NetworkPage { }
			}
		}
	}
}
