import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One wallpaper in the picker: a rounded thumbnail and the file name
Item {
    id: root

    required property string modelData // full path
    readonly property bool current: ListView.isCurrentItem

    signal activated

    implicitWidth: Appearance.sizes.wallpaperWidth
    implicitHeight: Appearance.sizes.wallpaperHeight + name.implicitHeight + Appearance.spacing.small

    // ClippingRectangle clips its children to its rounded shape (a plain Rectangle can't)
    ClippingRectangle {
        id: thumb

        width: parent.width
        height: Appearance.sizes.wallpaperHeight
        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer
        border.width: root.current ? 3 : 0
        border.color: Colours.palette.m3primary

        Image {
            anchors.fill: parent
            source: "file://" + root.modelData
            fillMode: Image.PreserveAspectCrop
            asynchronous: true // decode in the background so scrolling stays smooth
            // Decode at thumbnail size: your wallpapers are up to 5000 px wide
            sourceSize.width: thumb.width * 1.5
            sourceSize.height: thumb.height * 1.5
        }
    }

    StyledText {
        id: name

        anchors.top: thumb.bottom
        anchors.topMargin: Appearance.spacing.small
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        text: root.modelData.split("/").pop()
        font.pointSize: Appearance.font.size.small
        color: root.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
    }

    StateLayer {
        radius: Appearance.rounding.normal
        onClicked: root.activated()
    }
}
