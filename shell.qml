import QtQuick
import Quickshell
import qs.modules.bar

ShellRoot {
    settings.watchFiles: true
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}
