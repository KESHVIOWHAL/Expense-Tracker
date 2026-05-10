import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: splash
    anchors.fill: parent
    color: "#7C3AED"
    z: 100
    signal done()
    Column {
        anchors.centerIn: parent
        spacing: units.gu(2)
        Label { text: "₹"; font.pixelSize: units.gu(8); color: "white"; anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: "Expense Tracker"; font.pixelSize: units.gu(3); font.bold: true; color: "white"; anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: "by Keshvi"; font.pixelSize: units.gu(1.8); color: "#ffffff99"; anchors.horizontalCenter: parent.horizontalCenter }
    }
    Timer { interval: 2000; running: true; onTriggered: hideAnim.start() }
    NumberAnimation { id: hideAnim; target: splash; property: "opacity"; to: 0; duration: 500; onStopped: splash.done() }
}
