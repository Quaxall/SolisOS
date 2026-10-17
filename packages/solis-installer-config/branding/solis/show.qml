import QtQuick 2.0;
import QtQuick.Controls 2.0;

Rectangle {
    id: presentation
    color: "#0f1017"
    anchors.fill: parent

    SwipeView {
        id: view
        currentIndex: 0
        anchors.fill: parent

        Item {
            id: slide1
            Rectangle {
                anchors.fill: parent
                color: "#0f1017"
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    Text {
                        text: "☀️ Solis OS 0.2 (Solstice)"
                        font.pixelSize: 26
                        font.bold: true
                        color: "#FFB300"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: "Hızlı, Akıcı ve Windows 11 Fluent Design Estetiğinde Yeni Nesil Linux."
                        font.pixelSize: 14
                        color: "#D1D5DB"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Item {
            id: slide2
            Rectangle {
                anchors.fill: parent
                color: "#0f1017"
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    Text {
                        text: "🌌 Wayland & Akıcı Pencere Animasyonları"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#38BDF8"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: "KWin Wayland ile pencerelerde akıcı süzülme (Glide), akrilik bulanıklık ve Snap Assist."
                        font.pixelSize: 14
                        color: "#D1D5DB"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Item {
            id: slide3
            Rectangle {
                anchors.fill: parent
                color: "#0f1017"
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    Text {
                        text: "📦 Yerleşik Bağımsız Uygulama Havuzu"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#4ADE80"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: "LocalSend, Obsidian, Geary E-Posta, GNOME Not Defteri ve Takvim hazır gelir."
                        font.pixelSize: 14
                        color: "#D1D5DB"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: {
            view.currentIndex = (view.currentIndex + 1) % 3
        }
    }
}
