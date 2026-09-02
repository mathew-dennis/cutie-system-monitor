import Cutie
import QtQuick
import QtQuick.Layouts
import Cutie.SysMonitor

CutieWindow {
    id: mainWindow
    width: 400
    height: 800
    visible: true
    title: qsTr("System Monitor")

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
        }
    ]

    initialPage: CutiePage {
        width: mainWindow.width
        height: mainWindow.height

        ListView {
            id: listView
            model: mainWindow.pages
            anchors.fill: parent
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
                        if (comp.status === Component.Ready) {
                            mainWindow.pageStack.push(comp, {});
                        }
                    }
                }
            }
        }
    }
}