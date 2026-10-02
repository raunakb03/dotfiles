import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            color: "#cdd6f4"
            text: "Hello from my shell"
        }
    }
}
