import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris

// The top bar (replaces waybar), one per screen. Same modules, order, icons, clicks and
// look as the old waybar config: floating pills, height 36, 6px margins.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property string home: Quickshell.env("HOME")
        function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }

        visible: !BarCfg.hidden
        color: "transparent"
        anchors {
            top: BarCfg.position !== "bottom"
            bottom: BarCfg.position === "bottom"
            left: true; right: true
        }
        margins {
            top: BarCfg.position !== "bottom" ? BarCfg.margin : 0
            bottom: BarCfg.position === "bottom" ? BarCfg.margin : 0
            left: BarCfg.margin; right: BarCfg.margin
        }
        implicitHeight: BarCfg.height
        exclusiveZone: BarCfg.height
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qs-bar"

        // caffeine: the old waybar idle_inhibitor
        property bool caffeine: false
        IdleInhibitor { window: bar; enabled: bar.caffeine }

        // ---------------- left ----------------
        Row {
            anchors.left: parent.left
            height: parent.height
            spacing: 6

            BarPill {
                padding: 4
                BarButton { glyphWidth: 9; text: String.fromCodePoint(0xF0493); tooltip: "Flirps OS settings"; onClicked: bar.run(bar.home + "/.local/bin/settings") }
                BarButton { glyphWidth: 9; text: String.fromCodePoint(0xF0349); tooltip: "Search apps"; onClicked: bar.run(bar.home + "/.local/bin/qs-panel launcher") }
                BarButton {
                    glyphWidth: 9
                    text: String.fromCodePoint(0xF0594)
                    textColor: BarCfg.nightlight ? Theme.primary : Theme.text
                    tooltip: BarCfg.nightlight ? "Night light on" : "Night light off"
                    onClicked: bar.run(bar.home + "/.local/bin/nightlight toggle")
                }
                BarButton {
                    glyphWidth: 9
                    text: String.fromCodePoint(bar.caffeine ? 0xF0176 : 0xF06CA)
                    textColor: bar.caffeine ? Theme.primary : Theme.text
                    tooltip: bar.caffeine ? "Caffeine on: screen stays awake" : "Caffeine off"
                    onClicked: bar.caffeine = !bar.caffeine
                }
                BarButton { glyphWidth: 9; text: String.fromCodePoint(0xF049D); tooltip: "Random wallpaper"; onClicked: bar.run(bar.home + "/.local/bin/wallpaper random") }
            }

            // workspaces on this screen, sorted by number
            BarPill {
                padding: 4
                Repeater {
                    model: Hyprland.workspaces.values.filter(w => w.id > 0 && (!bar.monitor || !w.monitor || w.monitor === bar.monitor)).sort((a, b) => a.id - b.id)
                    Item {
                        id: wsItem
                        required property var modelData
                        readonly property bool active: bar.monitor && bar.monitor.activeWorkspace === modelData
                        width: wsBtn.width + 4; height: parent.height
                        Rectangle {
                            id: wsBtn
                            x: 2; y: 6
                            width: Math.max(31, wsText.implicitWidth + 16); height: parent.height - 12
                            radius: 8
                            color: wsItem.active ? Theme.primary : wsMa.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                            Text {
                                id: wsText
                                anchors.centerIn: parent
                                text: wsItem.modelData.name || wsItem.modelData.id
                                font.family: Theme.font; font.pixelSize: 13
                                color: wsItem.active ? Theme.fgPrimary : Theme.subtext
                            }
                            MouseArea { id: wsMa; anchors.fill: parent; hoverEnabled: true; onClicked: wsItem.modelData.activate() }
                        }
                    }
                }
            }

            // now playing
            BarPill {
                visible: Media.active
                padding: 0
                BarButton {
                    readonly property string line: (Media.playing ? String.fromCodePoint(0xF075A) : String.fromCodePoint(0xF03E4)) + "  " + (Media.player ? (Media.player.trackArtist || "") : "") + " — " + Media.title
                    text: line.length > 40 ? line.slice(0, 39) + "…" : line
                    fontSize: 13; hpad: 12; hoverFill: false
                    textColor: Media.playing ? Theme.text : Theme.subtext
                    tooltip: Media.player ? Media.title + "\n" + (Media.player.trackArtist || "") + " — " + (Media.player.trackAlbum || "") : ""
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel media")
                    onMiddleClicked: if (Media.player) Media.player.togglePlaying()
                    onRightClicked: bar.run(bar.home + "/.local/bin/qs-panel notifcenter")
                    onScrolled: d => { if (Media.player) { if (d > 0) Media.player.next(); else Media.player.previous(); } }
                }
            }
        }

        // ---------------- center: clock ----------------
        BarPill {
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 0
            BarButton {
                id: clock
                property date now: new Date()
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }
                text: Qt.formatTime(now, "HH:mm")
                fontSize: 17; bold: true; hpad: 16; hoverFill: false
                tooltipContent: calendarTip
                onClicked: bar.run(bar.home + "/.local/bin/qs-panel dashboard")
                onRightClicked: bar.run(bar.home + "/.local/bin/qs-panel notifcenter")
            }
        }
        Component {
            id: calendarTip
            // month calendar like waybar's {calendar} tooltip; today bold + underlined
            Column {
                readonly property date today: new Date()
                readonly property date first: new Date(today.getFullYear(), today.getMonth(), 1)
                readonly property int lead: (first.getDay() - Qt.locale().firstDayOfWeek + 7) % 7
                readonly property int days: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()
                spacing: 2
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(parent.today, "MMMM yyyy")
                    font.family: Theme.font; font.pixelSize: 13; color: Theme.text
                }
                Grid {
                    columns: 7; columnSpacing: 8; rowSpacing: 2
                    Repeater {
                        model: 7
                        Text {
                            required property int index
                            width: 18; horizontalAlignment: Text.AlignRight
                            text: Qt.locale().standaloneDayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                            font.family: Theme.font; font.pixelSize: 13; color: Theme.text
                        }
                    }
                    Repeater {
                        model: parent.parent.lead + parent.parent.days
                        Text {
                            required property int index
                            readonly property int day: index - parent.parent.lead + 1
                            width: 18; horizontalAlignment: Text.AlignRight
                            text: day > 0 ? day : ""
                            font.family: Theme.font; font.pixelSize: 13
                            font.bold: day === parent.parent.today.getDate()
                            font.underline: day === parent.parent.today.getDate()
                            color: Theme.text
                        }
                    }
                }
            }
        }

        // ---------------- right ----------------
        Row {
            anchors.right: parent.right
            height: parent.height
            spacing: 6

            // system tray
            BarPill {
                visible: SystemTray.items.values.length > 0
                spacing: 8
                Repeater {
                    model: SystemTray.items.values
                    Item {
                        id: trayItem
                        required property var modelData
                        width: 16; height: parent.height
                        Image {
                            anchors.centerIn: parent
                            width: 16; height: 16
                            sourceSize: Qt.size(32, 32)
                            source: trayItem.modelData.icon
                        }
                        MouseArea {
                            id: trayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onClicked: m => {
                                const it = trayItem.modelData;
                                const p = trayItem.mapToItem(null, 0, trayItem.height + 6);
                                if (m.button === Qt.MiddleButton) it.secondaryActivate();
                                else if (m.button === Qt.RightButton || it.onlyMenu) { if (it.hasMenu) it.display(bar, p.x, p.y); }
                                else it.activate();
                            }
                            onWheel: w => trayItem.modelData.scroll(w.angleDelta.y / 120, false)
                        }
                        BarTooltip { target: trayItem; text: trayItem.modelData.tooltipTitle || trayItem.modelData.title || ""; hovered: trayMa.containsMouse }
                    }
                }
            }

            // network, bluetooth, volume, battery
            BarPill {
                padding: 4
                BarButton {
                    glyphWidth: 9
                    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi && d.connected) || null
                    readonly property var wiredDev: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) || null
                    readonly property var net: wifiDev ? wifiDev.networks.values.find(n => n.connected) || null : null
                    readonly property int strength: net ? Math.round(net.signalStrength * 100) : 0
                    text: String.fromCodePoint(net ? [0xF091F, 0xF0922, 0xF0925, 0xF0928][Math.min(3, Math.floor(strength / 25))]
                                                   : wiredDev ? 0xF0200 : 0xF092E)
                    tooltip: net ? net.name + " (" + strength + "%)" : wiredDev ? wiredDev.name : ""
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings")
                    onRightClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings wifi")
                }
                BarButton {
                    glyphWidth: 9
                    readonly property var bt: Bluetooth.defaultAdapter
                    readonly property var connected: bt ? bt.devices.values.filter(d => d.connected) : []
                    text: String.fromCodePoint(!bt || !bt.enabled ? 0xF00B2 : connected.length ? 0xF00B1 : 0xF00AF)
                    tooltip: connected.map(d => d.name).join("\n")
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings")
                    onRightClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings bt")
                }
                BarButton {
                    glyphWidth: 9
                    readonly property real v: Audio.volume
                    text: String.fromCodePoint(Audio.muted ? 0xF0581 : [0xF057F, 0xF0580, 0xF057E][Math.min(2, Math.floor(v * 3))])
                    tooltip: "Volume " + Math.round(v * 100) + "%"
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings")
                    onMiddleClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings audio")
                    onRightClicked: Audio.toggleMute()
                    onScrolled: d => Audio.setVolume(Audio.volume + d * 0.05)
                }
                BarButton {
                    glyphWidth: 9
                    readonly property var b: UPower.displayDevice
                    readonly property int pct: b ? Math.round(b.percentage * 100) : 0
                    readonly property bool charging: !!b && b.state === UPowerDeviceState.Charging
                    readonly property bool plugged: !!b && (b.state === UPowerDeviceState.FullyCharged || b.state === UPowerDeviceState.PendingCharge)
                    function hm(sec) { const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60); return h + " h " + m + " min"; }
                    visible: !!b && b.isLaptopBattery
                    text: String.fromCodePoint(charging ? 0xF0084 : plugged ? 0xF140B : [0xF007A, 0xF007C, 0xF007E, 0xF0080, 0xF0082, 0xF0079][Math.min(5, Math.floor(pct * 6 / 100))])
                    textColor: charging ? Theme.primary : pct <= 12 ? Theme.error : pct <= 25 ? Theme.tertiary : Theme.text
                    tooltip: pct + "% — " + (charging && b.timeToFull > 0 ? "Time to full: " + hm(b.timeToFull)
                                             : !charging && !plugged && b && b.timeToEmpty > 0 ? "Time to empty: " + hm(b.timeToEmpty)
                                             : plugged ? (b.state === UPowerDeviceState.FullyCharged ? "Full" : "Plugged") : "Charging")
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel quicksettings")
                    onRightClicked: bar.run(bar.home + "/.local/bin/settings display")
                }
            }

            BarPill {
                padding: 0
                BarButton {
                    text: String.fromCodePoint(0xF0349) + "  Find anything…"
                    fontSize: 13; hpad: 12; minWidth: 174
                    textColor: Theme.subtext
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel launcher")
                }
            }

            BarPill {
                padding: 0
                BarButton {
                    text: String.fromCodePoint(0xF0425)
                    hpad: 13
                    tooltip: "Power"
                    hoverColor: Theme.error
                    hoverRadius: 10
                    hoverTextColor: Theme.fgPrimary
                    onClicked: bar.run(bar.home + "/.local/bin/qs-panel power")
                }
            }
        }
    }
}
