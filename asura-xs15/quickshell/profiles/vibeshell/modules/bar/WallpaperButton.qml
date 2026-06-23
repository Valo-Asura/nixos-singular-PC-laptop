import QtQuick
import qs.modules.components
import qs.modules.theme
import Quickshell

ToggleButton {
    id: wallpaperButton
    buttonIcon: Icons.wallpapers
    tooltipText: "Vibewall"
    onToggle: function () {
        Quickshell.execDetached(["vibewall", "toggle"]);
    }
}
