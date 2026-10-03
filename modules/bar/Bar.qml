import QtQuick
import Quickshell
import qs.services

PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: "#1e1e2e"
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: "#cdd6f4"
        text: root.modelData.name
    }
    Text {
        anchors.centerIn: parent
        color: "#cdd6f4"
        text: Time.time
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: "#cdd6f4"
        text: Time.format("dddd d MMMM")
    }
}
