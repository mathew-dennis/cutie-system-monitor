import Cutie
import QtQuick
import QtQuick.Layouts
import Cutie.SysMonitor
import Cutie.Battery
import Cutie.Systeminfo

CutieWindow {
    id: mainWindow
    width: 400
    height: 800
    visible: true
    title: qsTr("System Monitor")

    CutieSystemInfo {
        id: systemInfo
    }

    // Added specific colors and types to match the image branding
    property var pages: [
        {
            type: "cpu",
            title: qsTr("CPU"),
            color: "#1f77b4", // Blue
            componentPath: "PerformancePage.qml"
        },
        {
            type: "memory",
            title: qsTr("Memory"),
            color: "#800080", // Purple
            componentPath: "MemoryPage.qml"
        },
        {
            type: "network",
            title: qsTr("Wi-Fi"),
            color: "#d2691e", // Brown/Orange
            componentPath: "NetworkPage.qml"
        },
        {
            type: "disk",
            title: qsTr("Disk"),
            color: "#2ca02c", // Green
            componentPath: "DiskPage.qml"
        },
        {
            type: "battery",
            title: qsTr("Battery"),
            color: "#69a86e",
            componentPath: "BatteryPage.qml"
        }
    ]

    initialPage: CutiePage {
        width: mainWindow.width
        height: mainWindow.height

        ListView {
            id: listView
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: deviceInfoSummary.top
            }
            model: mainWindow.pages
            header: CutiePageHeader {
                title: mainWindow.title
            }

            delegate: Rectangle {
                width: listView.width
                height: 72
                // Basic selection highlight
                color: mouseArea.pressed ? Atmosphere.secondaryAlphaColor : "transparent"

				RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // 1. Thumbnail Graph Box
                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 48
                        color: "transparent"
                        border.color: modelData.color
                        border.width: 1

                        LineGraph {
                            anchors.fill: parent
                            anchors.margins: 1    // Keep line strictly inside the border
                            gridLines: 0          // Hide grid for thumbnail
                            verticalGridLines: 0  // Hide grid for thumbnail
                            lineColor: modelData.color
                            fillOpacity: 0.1
                            
                            // Auto-scale network max value, lock CPU/Mem to 1.0
                            maxValue: modelData.type === "network" ? 0 : 1.0
                            values: {
                                if (modelData.type === "cpu") return SysMonitor.cpu.history;
                                if (modelData.type === "memory") return SysMonitor.memory.usageHistory;
                                if (modelData.type === "network") return SysMonitor.network.receiveHistory;
                                if (modelData.type === "disk") return SysMonitor.disk.activeTimeHistory;
                                if (modelData.type === "battery") return BatteryHistory.points.map(function(point) { return Number(point.value) / 100; });
                                return [];
                            }
                        }
                    }

                    // 2. Dynamic Text Details
                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        CutieLabel {
                            text: modelData.title
                            font.pixelSize: 15
                            font.bold: true
                            horizontalAlignment: Text.AlignLeft // Explicitly force left
                        }

                        CutieLabel {
                            font.pixelSize: 12
                            opacity: 0.8
                            horizontalAlignment: Text.AlignLeft // Explicitly force left
                            text: {
                                if (modelData.type === "cpu") {
                                    return Math.round(SysMonitor.cpu.utilization * 100) + "%  " + SysMonitor.cpu.speed;
                                } else if (modelData.type === "memory") {
                                    let total = SysMonitor.memory.total;
                                    let inUse = SysMonitor.memory.inUse;
                                    let pct = total > 0 ? Math.round((inUse / total) * 100) : 0;
                                    return SysMonitor.formatBytes(inUse) + " / " + SysMonitor.formatBytes(total) + " (" + pct + "%)";
                                } else if (modelData.type === "network") {
                                    return "S: " + SysMonitor.formatRate(SysMonitor.network.sendSpeed) + 
                                           " R: " + SysMonitor.formatRate(SysMonitor.network.receiveSpeed);
                                } else if (modelData.type === "disk") {
                                    return Math.round(SysMonitor.disk.activeTime * 100) + "%  " +
                                           SysMonitor.disk.model;
                                } else if (modelData.type === "battery") {
                                    return Math.round(BatteryHistory.percentage) + "%  " + BatteryHistory.stateString;
                                }
                                return "";
                            }
                        }
                    }

                    
                    Item {
                        Layout.fillWidth: true 
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: {
                        var comp = Qt.createComponent(modelData.componentPath);
                        if (comp.status === Component.Ready)
                            mainWindow.pageStack.push(comp, {});
                    }
                }
            }
        }

        Rectangle {
            id: deviceInfoSummary
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 16
                rightMargin: 16
                bottomMargin: 12
            }
            clip: true
            height: 104
            color: Qt.rgba(Atmosphere.secondaryAlphaColor.r,
                Atmosphere.secondaryAlphaColor.g,
                Atmosphere.secondaryAlphaColor.b, 0.1)
            radius: 16

            GridLayout {
                anchors.fill: parent
                anchors.margins: 14
                columns: 2
                columnSpacing: 16
                rowSpacing: 8

                ColumnLayout {
                    spacing: 1
                    CutieLabel { text: qsTr("Shell"); font.pixelSize: 10; opacity: 0.65 }
                    CutieLabel { text: qsTr("Cutie Shell"); font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; maximumLineCount: 1 }
                }
                ColumnLayout {
                    spacing: 1
                    CutieLabel { text: qsTr("OS"); font.pixelSize: 10; opacity: 0.65 }
                    CutieLabel { text: systemInfo.osInfo.osName; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; maximumLineCount: 1 }
                }
                ColumnLayout {
                    spacing: 1
                    CutieLabel { text: qsTr("Kernel"); font.pixelSize: 10; opacity: 0.65 }
                    CutieLabel { text: systemInfo.osInfo.kernel; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; maximumLineCount: 1 }
                }
                ColumnLayout {
                    spacing: 1
                    CutieLabel { text: qsTr("Device"); font.pixelSize: 10; opacity: 0.65 }
                    CutieLabel { text: systemInfo.hwInfo.device; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; maximumLineCount: 1 }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var comp = Qt.createComponent("DeviceInformationPage.qml");
                    if (comp.status === Component.Ready)
                        mainWindow.pageStack.push(comp, { systemInfo: systemInfo });
                }
            }
        }
    }
}
