pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.globals

Singleton {
    id: root

    readonly property var themeModes: ["dark", "light", "auto"]
    readonly property var colorSchemes: ["Cherry Blossom", "OLED", "Catppuccin", "Rose Pine", "Tokyonight", "Nord", "Gruvbox", "Everforest", "Ayu"]
    readonly property var iconThemes: ["Papirus-Dark", "Papirus", "MoreWaita", "Tela-circle", "Adwaita"]
    readonly property var accentPresets: [
        { id: "coral", label: "Coral", colorName: "primary", hex: "#ff7a7f" },
        { id: "pink", label: "Pink", colorName: "magenta", hex: "#f472b6" },
        { id: "purple", label: "Purple", colorName: "blue", hex: "#a78bfa" },
        { id: "blue", label: "Blue", colorName: "blue", hex: "#60a5fa" },
        { id: "green", label: "Green", colorName: "green", hex: "#86efac" },
        { id: "amber", label: "Amber", colorName: "yellow", hex: "#fbbf24" }
    ]

    property string pendingScheme: ""

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function colorSchemePath(name) {
        const scheme = name === "OLED" ? "Cherry Blossom" : name;
        const mode = Config.theme.lightMode ? "light" : "dark";
        return Qt.resolvedUrl("../../assets/colors/" + scheme + "/" + mode + ".json").toString().replace("file://", "");
    }

    function accentById(id) {
        for (let i = 0; i < accentPresets.length; i++) {
            if (accentPresets[i].id === id)
                return accentPresets[i];
        }
        return accentPresets[0];
    }

    function saveTheme() {
        if (Config.saveTheme)
            Config.saveTheme();
        else
            Config.loader.writeAdapter();
    }

    function applyThemeMode(mode) {
        const normalized = themeModes.includes(mode) ? mode : "dark";
        Config.theme.themeMode = normalized;
        if (normalized === "light") {
            Config.theme.lightMode = true;
        } else if (normalized === "dark") {
            Config.theme.lightMode = false;
        } else {
            const hour = new Date().getHours();
            Config.theme.lightMode = hour >= 7 && hour < 18;
        }
        saveTheme();
        if (!Config.theme.useWallpaperColors)
            applyColorScheme(Config.theme.colorScheme || "Cherry Blossom");
    }

    function applyAccent(id) {
        const accent = accentById(id);
        Config.theme.accentPreset = accent.id;
        Config.theme.srPrimary.gradient = [[accent.colorName, 0.0]];
        Config.theme.srPrimary.border = [accent.colorName, 0];
        Config.theme.srBarBg.border = [accent.colorName, Config.theme.srBarBg.border[1] || 1];
        Config.bar.barColor = [[accent.colorName, 0.22]];
        Config.hyprland.activeBorderColor = [accent.colorName];
        saveTheme();
        Config.saveBar();
        Config.saveHyprland();
    }

    function applyColorScheme(name) {
        const normalized = colorSchemes.includes(name) ? name : "Cherry Blossom";
        Config.theme.colorScheme = normalized;
        Config.theme.useWallpaperColors = false;
        Config.theme.oledMode = normalized === "OLED";
        if (normalized === "OLED")
            Config.theme.lightMode = false;
        saveTheme();

        pendingScheme = normalized;
        copyColorsProcess.running = false;
        copyColorsProcess.command = [
            "bash",
            "-lc",
            "install -D -m 0644 " + shellQuote(colorSchemePath(normalized)) + " " + shellQuote(Quickshell.dataPath("colors.json"))
        ];
        copyColorsProcess.running = true;
    }

    function setWallpaperColorsEnabled(enabled) {
        Config.theme.useWallpaperColors = enabled;
        saveTheme();
        if (enabled && GlobalStates.wallpaperManager) {
            GlobalStates.wallpaperManager.setColorPreset("");
            GlobalStates.wallpaperManager.runMatugenForCurrentWallpaper();
        }
    }

    function applyIconTheme(name) {
        Config.theme.iconTheme = name;
        saveTheme();
        Quickshell.execDetached([
            "bash",
            "-lc",
            "gsettings set org.gnome.desktop.interface icon-theme " + shellQuote(name) + " || true"
        ]);
    }

    function openWallpaperSelector() {
        Quickshell.execDetached(["skwd-wall"]);
    }

    function resetTheme() {
        Config.theme.themeMode = "dark";
        Config.theme.lightMode = false;
        Config.theme.oledMode = false;
        Config.theme.roundness = 20;
        Config.theme.fontSize = 14;
        Config.theme.animDuration = 300;
        Config.theme.shadowOpacity = 0.5;
        applyAccent("coral");
        applyColorScheme("Cherry Blossom");
    }

    function reloadShell() {
        Quickshell.execDetached(["vibeshell", "reload"]);
    }

    Process {
        id: copyColorsProcess
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", "-a", "Vibeshell", "Theme apply failed", "Could not load " + root.pendingScheme + " colors."]);
            }
        }
    }
}
