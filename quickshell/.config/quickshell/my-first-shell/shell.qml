import QtQuick
import Quickshell
import qs.modules
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock

ShellRoot {
    settings.watchFiles: true

    Background {}

    Drawers {}

    Shortcuts {}

    Lock {}

    Idle {}
}
