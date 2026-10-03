import QtQuick
import Quickshell
import qs.modules
import qs.modules.background
import qs.modules.drawers

ShellRoot {
    settings.watchFiles: true

    Background {}

    Drawers {}

    Shortcuts {}
}
