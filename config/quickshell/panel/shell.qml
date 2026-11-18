import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    property bool opened: false
    property string currentId: ""
    property string currentName: ""
    property var themes: []
    property string armed: ""

    QtObject {
        id: c
        property color bg: "#0b1220"
        property color panel: "#111a2e"
        property color panel2: "#16223a"
        property color border: "#1b2a44"
        property color accent: "#61afef"
        property color text: "#e6e8ee"
        property color dim: "#5b6b8c"
        property color warn: "#e06c75"
    }

    property int volume: 0
    property bool muted: false
    property int bright: 0
    property bool wifi: false
    property string ssid: ""
    property bool bt: false
    property int bat: 0
    property string batstate: ""
    property int cpu: 0
    property int mem: 0
    property string uptime: ""
    property string profile: ""
    property string host: "archdavid"
    property string ws: ""
    property string wtitle: ""
    property string media: ""
    property bool playing: false

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.config/theme-switcher/panel.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.reloadTheme()
    }

    function reloadTheme() {
        try {
            const d = JSON.parse(themeFile.text());
            if (d.current) {
                c.bg = d.current.bg;
                c.panel = d.current.panel;
                c.panel2 = d.current.panel2;
                c.border = d.current.border;
                c.accent = d.current.accent;
                c.text = d.current.text;
                c.dim = d.current.dim;
                c.warn = d.current.warn;
                root.currentId = d.current.id;
                root.currentName = d.current.name;
            }
            if (d.themes) root.themes = d.themes;
        } catch (e) {
            console.log("panel: tema no valido", e);
        }
    }

    function act(a, v) {
        const cmd = ["bash", Quickshell.env("HOME") + "/.config/theme-switcher/panel-action.sh", a];
        if (v !== undefined && v !== null && v !== "") cmd.push(String(v));
        Quickshell.execDetached(cmd);
        quickRefresh.restart();
    }

    function power(a) {
        if (root.armed === a) {
            root.armed = "";
            armTimer.stop();
            root.act(a);
        } else {
            root.armed = a;
            armTimer.restart();
        }
    }

    Timer { id: armTimer; interval: 3500; onTriggered: root.armed = "" }
    Timer { id: quickRefresh; interval: 450; onTriggered: if (!statusProc.running) statusProc.running = true }

    Process {
        id: statusProc
        command: ["bash", Quickshell.env("HOME") + "/.config/theme-switcher/panel-status.sh"]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: {
                try {
                    const s = JSON.parse(statusOut.text);
                    root.volume = s.volume;
                    root.muted = s.muted;
                    root.bright = s.bright;
                    root.wifi = s.wifi;
                    root.ssid = s.ssid;
                    root.bt = s.bt;
                    root.bat = s.bat;
                    root.batstate = s.batstate;
                    root.cpu = s.cpu;
                    root.mem = s.mem;
                    root.uptime = s.uptime;
                    root.profile = s.profile;
                    root.host = s.host;
                    root.ws = s.ws;
                    root.wtitle = s.wtitle;
                    root.media = s.media;
                    root.playing = s.playing;
                } catch (e) {
                    console.log("panel: estado no valido", e);
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.opened = !root.opened }
        function open(): void { root.opened = true }
        function close(): void { root.opened = false }
    }

    onOpenedChanged: {
        if (opened) {
            Qt.callLater(function () { panel.forceActiveFocus(); });
            if (!statusProc.running) statusProc.running = true;
        }
    }

    PanelWindow {
        id: win
        anchors.top: true
        anchors.right: true
        anchors.bottom: true
        margins.top: 14
        margins.right: 14
        margins.bottom: 14
        implicitWidth: 384
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.namespace: "qs-panel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region { item: root.opened ? panel : zero }

        Item { id: zero; width: 0; height: 0 }

        Item {
            anchors.fill: parent
            clip: true

            Rectangle {
                id: panel
                width: parent.width
                height: parent.height
                x: root.opened ? 0 : width
                radius: 22
                color: Qt.rgba(c.panel.r, c.panel.g, c.panel.b, 0.90)
                border.width: 1
                border.color: Qt.rgba(c.border.r, c.border.g, c.border.b, 0.95)
                focus: root.opened

                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

                Keys.onEscapePressed: root.opened = false

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.08) }
                        GradientStop { position: 0.35; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(c.bg.r, c.bg.g, c.bg.b, 0.25) }
                    }
                }

                Column {
                    id: content
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 14
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    // Cabecera
                    Item {
                        width: parent.width
                        height: 52

                        Image {
                            id: logo
                            source: "file:///usr/share/pixmaps/archlinux-logo.png"
                            width: 32
                            height: 32
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.left: logo.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: root.host
                                color: c.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                text: "archdavid · " + root.uptime
                                color: c.dim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }

                        Rectangle {
                            id: pulse
                            width: 8
                            height: 8
                            radius: 4
                            color: c.accent
                            anchors.right: closeBtn.left
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }

                        Rectangle {
                            id: closeBtn
                            width: 28
                            height: 28
                            radius: 14
                            color: closeArea.containsMouse ? Qt.rgba(c.warn.r, c.warn.g, c.warn.b, 0.18) : "transparent"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 160 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: closeArea.containsMouse ? c.warn : c.dim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.opened = false
                            }
                        }
                    }

                    // Sistema
                    Rectangle {
                        width: parent.width
                        height: 122
                        radius: 16
                        color: Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 16
                                Text {
                                    text: "SISTEMA"
                                    color: c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.5
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.profile.toUpperCase()
                                    color: c.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Bar {
                                width: parent.width
                                label: "CPU"
                                value: root.cpu
                                fg: c.accent
                                bgc: c.border
                                txt: c.text
                            }
                            Bar {
                                width: parent.width
                                label: "RAM"
                                value: root.mem
                                fg: c.accent
                                bgc: c.border
                                txt: c.text
                            }

                            Item {
                                width: parent.width
                                height: 18
                                Text {
                                    text: "󰁹"
                                    color: root.bat <= 15 ? c.warn : c.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.bat + "% · " + root.batstate
                                    color: c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    anchors.left: parent.left
                                    anchors.leftMargin: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.ssid !== "" ? "󰖩 " + root.ssid : (root.wifi ? "󰖩 sin red" : "󰖪 wifi off")
                                    color: c.dim
                                    elide: Text.ElideRight
                                    width: parent.width * 0.55
                                    horizontalAlignment: Text.AlignRight
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Controles
                    Rectangle {
                        width: parent.width
                        height: 116
                        radius: 16
                        color: Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 16
                                Text {
                                    text: "CONTROLES"
                                    color: c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.5
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            SliderRow {
                                width: parent.width
                                icon: root.muted ? "󰖁" : (root.volume > 55 ? "󰕾" : (root.volume > 15 ? "󰖀" : "󰕿"))
                                value: root.volume
                                accent: c.accent
                                trackColor: c.border
                                textColor: c.text
                                onMoved: function (v) { root.act("volume", v); }
                                MouseArea {
                                    x: 0
                                    y: 0
                                    width: 22
                                    height: 26
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.act("mute")
                                }
                            }

                            SliderRow {
                                width: parent.width
                                icon: "󰃠"
                                value: root.bright
                                accent: c.accent
                                trackColor: c.border
                                textColor: c.text
                                onMoved: function (v) { root.act("brightness", v); }
                            }
                        }
                    }

                    // Interruptores
                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: 46
                            radius: 14
                            color: root.wifi ? Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.16)
                                             : Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                            border.width: 1
                            border.color: root.wifi ? c.accent : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    text: "󰖩"
                                    color: root.wifi ? c.accent : c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: "WiFi"
                                    color: root.wifi ? c.text : c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.act("wifi-toggle")
                            }
                        }

                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: 46
                            radius: 14
                            color: root.bt ? Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.16)
                                           : Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                            border.width: 1
                            border.color: root.bt ? c.accent : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    text: "󰂯"
                                    color: root.bt ? c.accent : c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: "Bluetooth"
                                    color: root.bt ? c.text : c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.act("bt-toggle")
                            }
                        }

                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: 46
                            radius: 14
                            color: root.armed === "suspend" ? Qt.rgba(c.warn.r, c.warn.g, c.warn.b, 0.22)
                                                           : Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                            border.width: 1
                            border.color: root.armed === "suspend" ? c.warn : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)
                            Behavior on color { ColorAnimation { duration: 180 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    text: ""
                                    color: root.armed === "suspend" ? c.warn : c.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: root.armed === "suspend" ? "¿Seguro?" : "Suspender"
                                    color: root.armed === "suspend" ? c.warn : c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.power("suspend")
                            }
                        }
                    }

                    // Temas
                    Rectangle {
                        width: parent.width
                        height: themeColumn.implicitHeight + 26
                        radius: 16
                        color: Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)

                        Column {
                            id: themeColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 13
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 18
                                Text {
                                    text: "TEMAS"
                                    color: c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.5
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.currentName
                                    color: c.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Grid {
                                id: themeGrid
                                width: parent.width
                                columns: 2
                                spacing: 8

                                Repeater {
                                    model: root.themes

                                    Rectangle {
                                        id: chip
                                        width: (themeGrid.width - themeGrid.spacing) / 2
                                        height: 44
                                        radius: 12
                                        property bool active: modelData.id === root.currentId
                                        property bool hovered: false
                                        color: active ? Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.16)
                                                     : (hovered ? Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.08)
                                                                : Qt.rgba(c.panel.r, c.panel.g, c.panel.b, 0.35))
                                        border.width: 1
                                        border.color: active ? c.accent : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.7)
                                        scale: hovered ? 1.02 : 1.0
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            Rectangle {
                                                width: 9
                                                height: 9
                                                radius: 4.5
                                                color: modelData.accent
                                                anchors.verticalCenter: parent.verticalCenter
                                                SequentialAnimation on opacity {
                                                    running: chip.active
                                                    loops: Animation.Infinite
                                                    NumberAnimation { to: 0.35; duration: 1000; easing.type: Easing.InOutSine }
                                                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                                                }
                                            }
                                            Text {
                                                text: modelData.name
                                                color: chip.active ? c.text : c.dim
                                                elide: Text.ElideRight
                                                width: parent.width - 26
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 11
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: chip.hovered = true
                                            onExited: chip.hovered = false
                                            onClicked: {
                                                if (!chip.active) root.act("theme", modelData.id);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Ahora
                    Rectangle {
                        width: parent.width
                        height: 92
                        radius: 16
                        color: Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 6

                            Item {
                                width: parent.width
                                height: 16
                                Text {
                                    text: "AHORA"
                                    color: c.dim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.5
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 34
                                    height: 16
                                    radius: 8
                                    color: Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.16)
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: "WS " + root.ws
                                        color: c.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.wtitle !== "" ? root.wtitle : "Sin ventana activa"
                                color: c.text
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                width: parent.width
                                text: root.media !== "" ? "♪ " + root.media : "♪ sin reproduccion"
                                color: root.playing ? c.accent : c.dim
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Image {
                    source: "file:///usr/share/pixmaps/archlinux-logo.png"
                    width: 140
                    height: 140
                    opacity: 0.05
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: powerRow.top
                    anchors.bottomMargin: 26
                }

                // Energía
                Row {
                    id: powerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 14
                    spacing: 8

                    Rectangle {
                        width: (parent.width - 16) / 3
                        height: 44
                        radius: 14
                        color: root.armed === "logout" ? Qt.rgba(c.warn.r, c.warn.g, c.warn.b, 0.22)
                                                       : Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: root.armed === "logout" ? c.warn : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.armed === "logout" ? "¿Salir?" : "󰍃"
                            color: root.armed === "logout" ? c.warn : c.dim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.power("logout")
                        }
                    }

                    Rectangle {
                        width: (parent.width - 16) / 3
                        height: 44
                        radius: 14
                        color: root.armed === "reboot" ? Qt.rgba(c.warn.r, c.warn.g, c.warn.b, 0.22)
                                                       : Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: root.armed === "reboot" ? c.warn : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.armed === "reboot" ? "¿Reiniciar?" : "󰜉"
                            color: root.armed === "reboot" ? c.warn : c.dim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: root.armed === "reboot" ? 11 : 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.power("reboot")
                        }
                    }

                    Rectangle {
                        width: (parent.width - 16) / 3
                        height: 44
                        radius: 14
                        color: root.armed === "poweroff" ? Qt.rgba(c.warn.r, c.warn.g, c.warn.b, 0.22)
                                                         : Qt.rgba(c.panel2.r, c.panel2.g, c.panel2.b, 0.55)
                        border.width: 1
                        border.color: root.armed === "poweroff" ? c.warn : Qt.rgba(c.border.r, c.border.g, c.border.b, 0.8)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.armed === "poweroff" ? "¿Apagar?" : "󰐥"
                            color: root.armed === "poweroff" ? c.warn : c.dim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: root.armed === "poweroff" ? 11 : 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.power("poweroff")
                        }
                    }
                }
            }
        }
    }
}
