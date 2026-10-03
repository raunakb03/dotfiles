import QtQuick
import Quickshell
import qs.modules.background
import qs.modules.bar

ShellRoot {
    settings.watchFiles: true

    Background {}

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
