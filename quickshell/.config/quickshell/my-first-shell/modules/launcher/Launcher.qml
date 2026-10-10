import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import qs.components
import qs.config
import qs.services
import "../../utils/fuzzy.js" as Fuzzy

// The launcher: slides up from the bottom edge. What it lists depends on how the
// search text starts:
//   (anything)   apps
//   >            the list of modes below
//   >wall …      wallpapers (a horizontal strip of thumbnails)
//   >clip …      clipboard history
//   >keys …      keybindings
Item {
    id: root

    required property bool open
    required property real centreX // horizontal centre of the free area (not covered by the bar)

    // The modes you can switch to by typing their prefix
    readonly property var modes: [
        {
            prefix: ">wall",
            name: "Wallpapers",
            detail: "Pick a wallpaper (and its colours)",
            icon: "wallpaper"
        },
        {
            prefix: ">clip",
            name: "Clipboard history",
            detail: "Copy something you copied before   (Super + V)",
            icon: "content_paste"
        },
        {
            prefix: ">keys",
            name: "Keybindings",
            detail: "Search your Hyprland shortcuts   (Super + /)",
            icon: "keyboard"
        }
    ]

    // Which mode the text is in, and the search query after the prefix
    readonly property string mode: {
        const text = search.text;
        for (const m of modes)
            if (text.startsWith(m.prefix))
                return m.prefix;
        return text.startsWith(">") ? ">" : "apps";
    }
    readonly property string query: (mode === "apps" || mode === ">" ? search.text : search.text.slice(mode.length)).trim()
    readonly property bool wallpaperMode: mode === ">wall"
    readonly property ListView currentList: wallpaperMode ? wallList : resultList
    readonly property real padding: Appearance.padding.large

    // Everything except wallpapers is shown as rows of { name, detail, image, icon, activate() }
    readonly property var results: {
        switch (mode) {
        case ">":
            return modes.filter(m => m.prefix.startsWith(search.text.trim())).map(m => ({
                        name: m.name,
                        detail: m.detail,
                        image: "",
                        icon: m.icon,
                        keepOpen: true,
                        activate: () => search.text = m.prefix + " "
                    }));
        case ">clip":
            return Fuzzy.filter(query, Clipboard.entries, e => e.preview).map(e => ({
                        name: e.preview,
                        detail: "",
                        image: "",
                        icon: "content_paste",
                        activate: () => Clipboard.copy(e.id)
                    }));
        case ">keys":
            return Fuzzy.filter(query, Keybinds.rows, r => `${r.description} ${r.keys}`).map(r => ({
                        name: r.description,
                        detail: r.keys,
                        image: "",
                        icon: "keyboard",
                        activate: () => {} // just a reference: Enter closes the launcher
                    }));
        case ">wall":
            return [];
        }
        return Apps.search(query).map(app => ({
                    name: app.name,
                    detail: app.comment || app.genericName,
                    image: Quickshell.iconPath(app.icon, true), // "" if no installed theme has it
                    icon: "apps",
                    activate: () => Apps.launch(app)
                }));
    }

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

    // Every time it opens: start with the requested text (e.g. ">clip " from Super + V),
    // fetch fresh data for the lists that change, and take the keyboard
    // Wallpaper picker: preview the colours of the wallpaper you point at (mouse) or move to
    // (← / →). Nothing is previewed just by opening the picker. When the target goes away (mouse
    // off the thumbnails, picker closed, left >wall mode), the current colours come back.
    property string hoveredWallpaper: ""
    property string keyboardWallpaper: ""
    readonly property string previewTarget: wallpaperMode && open ? (hoveredWallpaper || keyboardWallpaper) : ""

    onPreviewTargetChanged: Wallpapers.preview(previewTarget)

    // Keyboard in the wallpaper strip: move the selection and preview it
    function moveWallpaper(delta: int): void {
        if (delta > 0)
            wallList.incrementCurrentIndex();
        else
            wallList.decrementCurrentIndex();
        keyboardWallpaper = wallList.currentItem?.modelData ?? "";
    }

    onOpenChanged: {
        if (open) {
            Clipboard.refresh();
            Keybinds.refresh();
            search.text = ShellState.launcherText;
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

        // Rows: best match at the bottom, right above the search field
        ListView {
            id: resultList

            visible: !root.wallpaperMode
            width: parent.width
            height: Math.min(count, 7) * Appearance.sizes.launcherItemHeight
            verticalLayoutDirection: ListView.BottomToTop
            clip: true
            model: root.results
            highlightMoveDuration: Appearance.anim.durations.small

            highlight: StyledRect {
                radius: Appearance.rounding.full
                color: Colours.palette.m3secondaryContainer
            }

            delegate: ResultItem {
                width: resultList.width
                onActivated: {
                    modelData.activate();
                    if (!modelData.keepOpen)
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
                onHoveredChanged: {
                    if (hovered)
                        root.hoveredWallpaper = modelData;
                    else if (root.hoveredWallpaper === modelData)
                        root.hoveredWallpaper = "";
                }
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
            color: Colours.palette.m3onSurfaceVariant
            text: {
                switch (root.mode) {
                case ">wall":
                    return `No wallpapers found in ${Wallpapers.dir}`;
                case ">clip":
                    return root.query ? "No matching clipboard entries" : "Clipboard history is empty";
                case ">keys":
                    return "No matching keybindings";
                case ">":
                    return "No such mode";
                }
                return "No matching apps";
            }
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
            placeholderText: "Search apps, or type > for more"
            placeholderTextColor: Colours.palette.m3outline
            background: StyledRect {
                radius: Appearance.rounding.full
                color: Colours.palette.m3surfaceContainerHigh

                MaterialIcon {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.palette.m3onSurfaceVariant
                    text: ({
                            ">wall": "wallpaper",
                            ">clip": "content_paste",
                            ">keys": "keyboard",
                            ">": "terminal"
                        })[root.mode] ?? "search"
                }
            }

            // A new search starts at the best match
            onTextChanged: {
                resultList.currentIndex = 0;
                wallList.currentIndex = 0;
                root.keyboardWallpaper = "";
            }

            onAccepted: root.activate()
            Keys.onEscapePressed: ShellState.closeLauncher()
            // The list grows upwards, so "up" means the next item
            Keys.onUpPressed: if (!root.wallpaperMode) resultList.incrementCurrentIndex()
            Keys.onDownPressed: if (!root.wallpaperMode) resultList.decrementCurrentIndex()
            Keys.onTabPressed: root.wallpaperMode ? root.moveWallpaper(1) : resultList.incrementCurrentIndex()
            Keys.onBacktabPressed: root.wallpaperMode ? root.moveWallpaper(-1) : resultList.decrementCurrentIndex()
            // Left/Right move the cursor in the text, except in the wallpaper strip
            Keys.onLeftPressed: event => {
                if (root.wallpaperMode) root.moveWallpaper(-1);
                else event.accepted = false;
            }
            Keys.onRightPressed: event => {
                if (root.wallpaperMode) root.moveWallpaper(1);
                else event.accepted = false;
            }
        }
    }
}
