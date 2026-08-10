import Cutie
import QtQuick

CutieWindow {
	id: mainWindow
	width: 400
	height: 800
	visible: true
	title: qsTr("System Monitor")

	property var pages: [
		{
			text: qsTr("Performance"),
			icon: "utilities-system-monitor-symbolic",
			component: Qt.createComponent("PerformancePage.qml")
		},
		{
			text: qsTr("Memory"),
			icon: "drive-harddisk-symbolic",
			component: Qt.createComponent("MemoryPage.qml")
		},
		{
			text: qsTr("Network"),
			icon: "network-transmit-receive-symbolic",
			component: Qt.createComponent("NetworkPage.qml")
		}
	]

	initialPage: CutiePage {
		width: mainWindow.width
		height: mainWindow.height

		ListView {
			model: mainWindow.pages
			anchors.fill: parent
			header: CutiePageHeader {
				title: mainWindow.title
			}

			delegate: CutieListItem {
				text: mainWindow.pages[index]["text"]
				icon.name: mainWindow.pages[index]["icon"]
				icon.color: Atmosphere.textColor

				onClicked: {
					if (mainWindow.pages[index]["component"].status === Component.Ready) {
						mainWindow.pageStack.push(
							mainWindow.pages[index]["component"]
							, {});
					}
				}
			}
		}
	}
}
