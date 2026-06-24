pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.globals
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 400

    property string hostname: ""
    property string osName: ""
    property string osIcon: ""
    property var linuxLogos: null
    property real chartZoom: 1.0
    property var processRows: []

    onChartZoomChanged: {
        SystemResources.maxHistoryPoints = 250;
    }

    // Function to get OS icon based on name
    function getOsIcon(osName) {
        if (!osName || !linuxLogos) {
            return "";
        }

        // Try exact match first
        if (linuxLogos[osName]) {
            return linuxLogos[osName];
        }

        // Try partial match
        for (const distro in linuxLogos) {
            if (osName.toLowerCase().includes(distro.toLowerCase())) {
                return linuxLogos[distro];
            }
        }

        // Default to generic Linux icon
        return linuxLogos["Linux"] || "";
    }

    function formatBytesAsGB(bytes) {
        const value = Number(bytes || 0);
        if (!value || value <= 0)
            return "0.0 GB";
        return `${(value / 1024 / 1024 / 1024).toFixed(1)} GB`;
    }

    function compactCpuName(name) {
        let value = (name || "CPU").trim();
        value = value.replace(/\(R\)|\(TM\)|CPU|Processor/gi, "");
        value = value.replace(/12th Gen\s+/i, "12th ");
        value = value.replace(/Intel\s+Core\s+/i, "Intel ");
        value = value.replace(/\s+/g, " ").trim();
        return value || "CPU";
    }

    function compactGpuName(name) {
        let value = (name || "GPU").trim();
        value = value.replace(/NVIDIA\s+GeForce\s+/i, "");
        value = value.replace(/\s+Laptop\s+GPU/i, " Laptop");
        value = value.replace(/\s+Laptop$/i, "");
        value = value.replace(/\s+Graphics/i, "");
        value = value.replace(/\s+/g, " ").trim();
        return value || "GPU";
    }

    function rssToMB(kib) {
        const value = Number(kib || 0);
        return `${Math.max(1, Math.round(value / 1024))} MB`;
    }

    function parseProcessRows(text) {
        const rows = [];
        const lines = (text || "").trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;
            const parts = line.split(/\s+/);
            if (parts.length < 4)
                continue;
            rows.push({
                pid: parts[0],
                cpu: Number(parts[1] || 0),
                rss: Number(parts[2] || 0),
                name: parts.slice(3).join(" ")
            });
        }
        rows.sort((a, b) => {
            const rssDiff = b.rss - a.rss;
            if (Math.abs(rssDiff) > 1024)
                return rssDiff;
            return b.cpu - a.cpu;
        });
        return rows;
    }

    // Update OS icon when logos are loaded
    onLinuxLogosChanged: {
        if (linuxLogos && osName) {
            const icon = getOsIcon(osName);
            osIcon = icon || "";
        }
    }

    // Load refresh interval from state
    Component.onCompleted: {
        // Always store maximum (250 points) to allow smooth zooming
        SystemResources.maxHistoryPoints = 250;

        const savedInterval = StateService.get("metricsRefreshInterval", 2000);
        SystemResources.updateInterval = Math.max(100, savedInterval);
        const savedZoom = StateService.get("metricsChartZoom", 1.0);
        // Limit zoom range: 0.2 (show all available) to 3.0 (zoom in)
        chartZoom = Math.max(0.2, Math.min(3.0, savedZoom));

        hostnameReader.running = true;
        osReader.running = true;
        linuxLogosReader.running = true;
        processReader.running = true;
    }

    // Load Linux logos JSON
    Process {
        id: linuxLogosReader
        running: false
        command: ["cat", Qt.resolvedUrl("../../../../assets/linux-logos.json").toString().replace("file://", "")]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    if (!text || text.trim().length === 0) {
                        console.warn("linux-logos.json is empty");
                        return;
                    }
                    root.linuxLogos = JSON.parse(text);
                    console.log("Loaded", Object.keys(root.linuxLogos).length, "Linux logos");
                } catch (e) {
                    console.warn("Failed to parse linux-logos.json:", e);
                    console.warn("Text received:", text.substring(0, 100));
                }
            }
        }
    }

    // Get hostname
    Process {
        id: hostnameReader
        running: false
        command: ["hostname"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const host = text.trim();
                if (host) {
                    root.hostname = host.charAt(0).toUpperCase() + host.slice(1);
                }
            }
        }
    }

    // Get OS name
    Process {
        id: osReader
        running: false
        command: ["sh", "-c", "grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"'"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const os = text.trim();
                if (os) {
                    root.osName = os;
                    // Only set icon if logos are already loaded
                    if (root.linuxLogos) {
                        const icon = getOsIcon(os);
                        root.osIcon = icon || "";
                    }
                }
            }
        }
    }

    Timer {
        id: processRefreshTimer
        interval: SystemResources.updateInterval
        repeat: true
        running: true
        onTriggered: {
            if (!processReader.running)
                processReader.running = true;
        }
    }

    Process {
        id: processReader
        running: false
        command: ["sh", "-lc", "ps -eo pid=,pcpu=,rss=,comm= --sort=-rss | head -n 18"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.processRows = root.parseProcessRows(text)
        }
    }

    Process {
        id: killProcess
        running: false
        onExited: processReader.running = true
    }

    function endProcess(pid) {
        if (!pid)
            return;
        killProcess.command = ["kill", "-TERM", String(pid)];
        killProcess.running = true;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left panel - Resources
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: "transparent"
            radius: Styling.radius(4)

            ColumnLayout {
                anchors.fill: parent
                spacing: 2

                // User info section - Avatar left, info right
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    spacing: 16

                    // User avatar
                    StyledRect {
                        id: avatarContainer
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 96
                        radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                        variant: "primary"

                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            anchors.margins: 2
                            source: `file://${Quickshell.env("HOME")}/.face.icon?${GlobalStates.avatarCacheBuster}`
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                                maskSource: ShaderEffectSource {
                                    sourceItem: Rectangle {
                                        width: userAvatar.width
                                        height: userAvatar.height
                                        radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Icons.user
                            font.family: Icons.font
                            font.pixelSize: 48
                            color: Colors.overSurfaceVariant
                            visible: userAvatar.status !== Image.Ready
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: GlobalStates.pickUserAvatar()

                            Rectangle {
                                anchors.fill: parent
                                color: Colors.overSurface
                                opacity: parent.containsMouse ? 0.1 : 0
                                radius: avatarContainer.radius

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }
                    }

                    // User info column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // Username
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: Icons.user
                                font.family: Icons.font
                                font.pixelSize: Config.theme.fontSize + 2
                                color: Styling.srItem("overprimary")
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    const user = Quickshell.env("USER") || "user";
                                    return user.charAt(0).toUpperCase() + user.slice(1);
                                }
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: Font.Medium
                                color: Colors.overBackground
                                elide: Text.ElideRight
                            }
                        }

                        // Hostname
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: Icons.at
                                font.family: Icons.font
                                font.pixelSize: Config.theme.fontSize + 2
                                color: Styling.srItem("overprimary")
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    if (!root.hostname)
                                        return "Hostname";
                                    const host = root.hostname.toLowerCase();
                                    return host.charAt(0).toUpperCase() + host.slice(1);
                                }
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: Font.Medium
                                color: Colors.overBackground
                                elide: Text.ElideRight
                            }
                        }

                        // OS
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: root.osIcon || (root.linuxLogos ? (root.linuxLogos["Linux"] || "") : "")
                                font.family: "Symbols Nerd Font Mono"
                                font.pixelSize: Config.theme.fontSize + 2
                                color: Styling.srItem("overprimary")
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.osName || "Linux"
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: Font.Medium
                                color: Colors.overBackground
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    contentHeight: resourcesColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: resourcesColumn
                        width: parent.width
                        spacing: 12

                        // CPU
                        Column {
                            width: parent.width
                            spacing: 4

                            ResourceItem {
                                width: parent.width
                                icon: Icons.cpu
                                label: "CPU"
                                value: SystemResources.cpuUsage / 100
                                barColor: Colors.red
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: root.compactCpuName(SystemResources.cpuModel)
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Colors.overBackground
                                    elide: Text.ElideMiddle
                                    Layout.maximumWidth: 190
                                }

                                Separator {
                                    Layout.preferredHeight: 2
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: `${Math.round(SystemResources.cpuUsage)}%`
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    font.weight: Font.Medium
                                    color: Colors.overBackground
                                }

                                Text {
                                    visible: SystemResources.cpuTemp >= 0
                                    text: Icons.temperature
                                    font.family: Icons.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Colors.red
                                }

                                Text {
                                    visible: SystemResources.cpuTemp >= 0
                                    text: `${SystemResources.cpuTemp}°`
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    font.weight: Font.Medium
                                    color: Colors.overBackground
                                }
                            }
                        }

                        // RAM
                        Column {
                            width: parent.width
                            spacing: 4

                            ResourceItem {
                                width: parent.width
                                icon: Icons.ram
                                label: "RAM"
                                value: SystemResources.ramUsage / 100
                                barColor: Colors.cyan
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: {
                                        const usedGB = (SystemResources.ramUsed / 1024 / 1024).toFixed(1);
                                        const totalGB = (SystemResources.ramTotal / 1024 / 1024).toFixed(1);
                                        return `${usedGB} GB / ${totalGB} GB`;
                                    }
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Colors.overBackground
                                    elide: Text.ElideMiddle
                                }

                                Separator {
                                    Layout.preferredHeight: 2
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: `${Math.round(SystemResources.ramUsage)}%`
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    font.weight: Font.Medium
                                    color: Colors.overBackground
                                }
                            }
                        }

                        // GPUs (if detected) - show one bar per GPU
                        Repeater {
                            id: gpuRepeater
                            model: SystemResources.gpuDetected ? SystemResources.gpuCount : 0

                            Column {
                                required property int index
                                width: parent.width
                                spacing: 4

                                ResourceItem {
                                    width: parent.width
                                    icon: Icons.gpu
                                    label: {
                                        const name = SystemResources.gpuNames[index] || "";
                                        const vendor = SystemResources.gpuVendors[index] || "";

                                        // If we have a descriptive name, use it
                                        if (name && name !== `${vendor.toUpperCase()} GPU ${index}`) {
                                            return root.compactGpuName(name);
                                        }
                                        // Otherwise show GPU index if multiple, or just "GPU" if single
                                        return SystemResources.gpuCount > 1 ? `GPU ${index}` : "GPU";
                                    }
                                    value: (SystemResources.gpuUsages[index] || 0) / 100
                                    barColor: {
                                        // Color based on vendor
                                        const vendor = SystemResources.gpuVendors[index] || "";
                                        switch (vendor.toLowerCase()) {
                                        case "nvidia":
                                            return Colors.green;
                                        case "amd":
                                            return Colors.red;
                                        case "intel":
                                            return Colors.blue;
                                        default:
                                            return Colors.magenta;
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: {
                                            const name = SystemResources.gpuNames[index] || "";
                                            return root.compactGpuName(name);
                                        }
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overBackground
                                        elide: Text.ElideMiddle
                                        Layout.maximumWidth: 190
                                    }

                                    Separator {
                                        Layout.preferredHeight: 2
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: `${Math.round(SystemResources.gpuUsages[index] || 0)}%`
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        font.weight: Font.Medium
                                        color: Colors.overBackground
                                    }

                                    Text {
                                        visible: (SystemResources.gpuTemps[index] ?? -1) >= 0
                                        text: Icons.temperature
                                        font.family: Icons.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: {
                                            const vendor = SystemResources.gpuVendors[index] || "";
                                            switch (vendor.toLowerCase()) {
                                            case "nvidia":
                                                return Colors.green;
                                            case "amd":
                                                return Colors.red;
                                            case "intel":
                                                return Colors.blue;
                                            default:
                                                return Colors.magenta;
                                            }
                                        }
                                    }

                                    Text {
                                        visible: (SystemResources.gpuTemps[index] ?? -1) >= 0
                                        text: `${SystemResources.gpuTemps[index]}°`
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        font.weight: Font.Medium
                                        color: Colors.overBackground
                                    }
                                }
                            }
                        }

                        // Disks
                        Repeater {
                            id: diskRepeater
                            model: SystemResources.validDisks

                            Column {
                                required property string modelData
                                width: parent.width
                                spacing: 4

                                ResourceItem {
                                    width: parent.width
                                    icon: {
                                        const diskType = SystemResources.diskTypes[modelData] || "unknown";
                                        switch (diskType) {
                                        case "ssd":
                                            return Icons.ssd;
                                        case "hdd":
                                            return Icons.hdd;
                                        default:
                                            return Icons.disk;
                                        }
                                    }
                                    label: modelData
                                    value: SystemResources.diskUsage[modelData] ? SystemResources.diskUsage[modelData] / 100 : 0
                                    barColor: Colors.yellow
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: {
                                            const used = SystemResources.diskUsed[modelData] || 0;
                                            const total = SystemResources.diskTotal[modelData] || 0;
                                            if (total > 0)
                                                return `${root.formatBytesAsGB(used)} / ${root.formatBytesAsGB(total)}`;
                                            return modelData;
                                        }
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overBackground
                                        elide: Text.ElideMiddle
                                    }

                                    Separator {
                                        Layout.preferredHeight: 2
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: `${Math.round((SystemResources.diskUsage[modelData] || 0))}%`
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        font.weight: Font.Medium
                                        color: Colors.overBackground
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right panel - Processes
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Styling.radius(4)
                variant: "pane"

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Styling.radius(0)
                    variant: "internalbg"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Processes"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(2)
                                    font.weight: Font.Bold
                                    color: Colors.overBackground
                                }

                                Text {
                                    text: "Sorted by memory first, then CPU. End sends TERM."
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Colors.overBackground
                                    opacity: 0.7
                                }
                            }

                            Text {
                                text: `${SystemResources.updateInterval}ms`
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                color: Colors.overBackground
                                opacity: 0.75
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "APP"
                                Layout.fillWidth: true
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                font.weight: Font.Bold
                                color: Colors.overBackground
                                opacity: 0.6
                            }

                            Text {
                                text: "CPU"
                                Layout.preferredWidth: 48
                                horizontalAlignment: Text.AlignRight
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                font.weight: Font.Bold
                                color: Colors.overBackground
                                opacity: 0.6
                            }

                            Text {
                                text: "RAM"
                                Layout.preferredWidth: 64
                                horizontalAlignment: Text.AlignRight
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                font.weight: Font.Bold
                                color: Colors.overBackground
                                opacity: 0.6
                            }

                            Item {
                                Layout.preferredWidth: 58
                            }
                        }

                        ListView {
                            id: processList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: root.processRows

                            delegate: StyledRect {
                                required property var modelData
                                width: processList.width
                                height: 36
                                radius: Styling.radius(-4)
                                variant: rowMouse.containsMouse ? "focus" : "internalbg"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-1)
                                        color: Colors.overBackground
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.preferredWidth: 48
                                        text: `${modelData.cpu.toFixed(1)}%`
                                        horizontalAlignment: Text.AlignRight
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overBackground
                                        opacity: 0.85
                                    }

                                    Text {
                                        Layout.preferredWidth: 64
                                        text: root.rssToMB(modelData.rss)
                                        horizontalAlignment: Text.AlignRight
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overBackground
                                        opacity: 0.85
                                    }

                                    StyledRect {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 24
                                        radius: Styling.radius(-5)
                                        variant: endMouse.containsMouse ? "primary" : "pane"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "End"
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-2)
                                            font.weight: Font.Bold
                                            color: endMouse.containsMouse ? Colors.overPrimary : Colors.overBackground
                                        }

                                        MouseArea {
                                            id: endMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: root.endProcess(modelData.pid)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
