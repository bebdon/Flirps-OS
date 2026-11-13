import QtQuick
import QtQuick.Layouts
import Quickshell

Page {
    id: page

    readonly property string greeting: {
        const h = new Date().getHours();
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 220
        RoundedImage {
            anchors.fill: parent
            radius: 24
            source: Backend.get("wallpaper", "current", "") ? "file://" + Backend.get("wallpaper", "current", "") : ""
            sourceSize: Qt.size(1600, 900)
        }
        Rectangle {
            anchors.fill: parent; radius: 24
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.65) }
                GradientStop { position: 0.7; color: "transparent" }
            }
        }
        Column {
            anchors.left: parent.left; anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            SText { text: page.greeting + ","; color: "white"; font.pixelSize: 26; font.weight: Font.Bold }
            SText { text: Backend.home.split("/").pop(); color: Theme.primary; font.pixelSize: 26; font.weight: Font.Bold }
            SText { text: "Welcome to " + Brand.name + " " + Brand.version + ". Everything here edits your real configs directly."; color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 }
        }
    }

    SectionTitle { text: "Quick toggles" }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 10; rowSpacing: 10
        QuickTile {
            icon: 0xF0594; title: "Night light"
            subtitle: Backend.get("display", "nightlight", false) ? Backend.get("display", "nightlight_temp", 4000) + "K" : "Off"
            on: Backend.get("display", "nightlight", false)
            onClicked: Backend.set("display", "nightlight", !on)
        }
        QuickTile {
            icon: on ? 0xF009B : 0xF009A; title: "Do not disturb"
            subtitle: on ? "Notifications silenced" : "Off"
            on: Backend.get("notif", "dnd", false)
            onClicked: Backend.set("notif", "dnd", !on)
        }
        QuickTile {
            icon: 0xF0176; title: "Caffeine"
            subtitle: on ? "Screen stays awake" : "Idle actions active"
            on: !Backend.get("idle", "enabled", true)
            onClicked: Backend.set("idle", "enabled", on)
        }
        QuickTile {
            icon: 0xF049D; title: "Shuffle wallpaper"
            subtitle: "Pick a random one and recolour"
            onClicked: Backend.set("wallpaper", "random", "1")
        }
    }

    SectionTitle { text: "System tools" }
    Flow {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: [
                { label: "Wi-Fi", icon: 0xF05A9, cmd: "~/.local/bin/qs-panel quicksettings wifi" },
                { label: "Advanced network", icon: 0xF0318, cmd: "nm-connection-editor" },
                { label: "Bluetooth", icon: 0xF00AF, cmd: "~/.local/bin/qs-panel quicksettings bt" },
                { label: "Sound", icon: 0xF057E, cmd: "~/.local/bin/qs-panel quicksettings audio" },
                { label: "GTK appearance", icon: 0xF03D8, cmd: "nwg-look" },
                { label: "Hyprland config", icon: 0xF0493, cmd: "kitty -e ${EDITOR:-nano} ~/.config/hypr/config/settings.lua" }
            ]
            PillButton {
                required property var modelData
                text: modelData.label
                icon: modelData.icon
                filled: false
                color: Theme.surfaceHigh
                onClicked: Quickshell.execDetached(["sh", "-c", modelData.cmd])
            }
        }
    }

    SectionTitle { text: "Power" }
    OptionRow {
        icon: 0xF0241; title: "Power profile"
        Dropdown {
            value: Backend.get("display", "power", "balanced")
            options: [{ label: "Power saver", value: "power-saver" }, { label: "Balanced", value: "balanced" }, { label: "Performance", value: "performance" }]
            onPicked: v => Backend.set("display", "power", v)
        }
    }
}
