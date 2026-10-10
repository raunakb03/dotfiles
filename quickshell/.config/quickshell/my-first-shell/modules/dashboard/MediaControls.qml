import QtQuick
import qs.components
import qs.services

// Previous / play-pause / next for the active player
Row {
    id: root

    property real size: 40
    readonly property var player: Players.active

    spacing: 4

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "skip_previous"
        size: root.size
        disabled: !root.player?.canGoPrevious
        onClicked: Players.previous()
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: root.player?.isPlaying ? "pause" : "play_arrow"
        filled: true
        size: root.size * 1.25
        disabled: !root.player?.canTogglePlaying
        onClicked: Players.togglePlaying()
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "skip_next"
        size: root.size
        disabled: !root.player?.canGoNext
        onClicked: Players.next()
    }
}
