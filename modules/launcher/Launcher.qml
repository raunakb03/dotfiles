import QtQuick
import QtQuick.Controls.Basic
import qs.components
import qs.config
import qs.services

// The launcher: slides up from the bottom edge. Type to search apps;
// start with ">wall" to pick a wallpaper instead.
Item {
    id: root

    required property bool open
    required property real centreX // horizontal centre of the free area (not covered by the bar)

    readonly property bool wallpaperMode: search.text.startsWith(">wall")
    readonly property string query: wallpaperMode ? search.text.slice(5) : search.text
    readonly property ListView currentList: wallpaperMode ? wallList : appList
    readonly property real padding: Appearance.padding.large

    function activate(): void {
        const item = currentList.currentItem;
        if (item)
            item.activated();
    }

    width: Appearance.sizes.launcherWidth + padding * 2
    height: open ? content.implicitHeight + padding * 2 : 0
    x: centreX - width / 2
    anchors.bottom: parent.bottom
    clip: true

    Behavior on height {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    // Every time it opens: start with an empty search, and take the keyboard
    onOpenChanged: {
        if (open) {
            search.text = "";
            search.forceActiveFocus();
        }
    }

    Column {
        id: content

        // Anchored to the bottom, so as the launcher grows the content rises out of the screen edge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.padding
        anchors.horizontalCenter: parent.horizontalCenter
        width: Appearance.sizes.launcherWidth
        spacing: Appearance.spacing.normal

        // Apps: best match at the bottom, right above the search field
        ListView {
            id: appList

            visible: !root.wallpaperMode
            width: parent.width
            height: Math.min(count, 7) * Appearance.sizes.launcherItemHeight
            verticalLayoutDirection: ListView.BottomToTop
            clip: true
            model: root.wallpaperMode ? [] : Apps.search(root.query)
            highlightMoveDuration: Appearance.anim.durations.small

            highlight: StyledRect {
                radius: Appearance.rounding.full
                color: Colours.palette.m3secondaryContainer
            }

            delegate: AppItem {
                width: appList.width
                onActivated: {
                    Apps.launch(modelData);
                    ShellState.closeLauncher();
                }
            }
        }

        // Wallpapers: a horizontal strip, the selected one kept in the middle
        ListView {
            id: wallList

            visible: root.wallpaperMode && count > 0
            width: parent.width
            height: Appearance.sizes.wallpaperHeight + 30
            orientation: ListView.Horizontal
            spacing: Appearance.spacing.normal
            clip: true
            model: root.wallpaperMode ? Wallpapers.search(root.query) : []
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - Appearance.sizes.wallpaperWidth) / 2
            preferredHighlightEnd: (width + Appearance.sizes.wallpaperWidth) / 2
            highlightMoveDuration: Appearance.anim.durations.small

            delegate: WallpaperItem {
                onActivated: {
                    Wallpapers.set(modelData);
                    ShellState.closeLauncher();
                }
            }
        }

        StyledText {
            visible: root.currentList.count === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.wallpaperMode ? `No wallpapers found in ${Wallpapers.dir}` : "No matching apps"
            color: Colours.palette.m3onSurfaceVariant
        }

        // The search field
        TextField {
            id: search

            width: parent.width
            leftPadding: Appearance.padding.large + searchIcon.width + Appearance.spacing.small
            topPadding: Appearance.padding.normal
            bottomPadding: Appearance.padding.normal
            color: Colours.palette.m3onSurface
            font.family: Appearance.font.family.sans
            font.pointSize: Appearance.font.size.normal
            placeholderText: "Search apps, or type >wall for wallpapers"
            placeholderTextColor: Colours.palette.m3outline
            background: StyledRect {
                radius: Appearance.rounding.full
                color: Colours.palette.m3surfaceContainerHigh

                MaterialIcon {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wallpaperMode ? "wallpaper" : "search"
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // A new search starts at the best match
            onTextChanged: {
                appList.currentIndex = 0;
                wallList.currentIndex = 0;
            }

            onAccepted: root.activate()
            Keys.onEscapePressed: ShellState.closeLauncher()
            // The app list grows upwards, so "up" means the next item
            Keys.onUpPressed: if (!root.wallpaperMode) appList.incrementCurrentIndex()
            Keys.onDownPressed: if (!root.wallpaperMode) appList.decrementCurrentIndex()
            Keys.onTabPressed: root.currentList.incrementCurrentIndex()
            Keys.onBacktabPressed: root.currentList.decrementCurrentIndex()
            // Left/Right move the cursor in the text, except in the wallpaper strip
            Keys.onLeftPressed: event => {
                if (root.wallpaperMode) wallList.decrementCurrentIndex();
                else event.accepted = false;
            }
            Keys.onRightPressed: event => {
                if (root.wallpaperMode) wallList.incrementCurrentIndex();
                else event.accepted = false;
            }
        }
    }
}
