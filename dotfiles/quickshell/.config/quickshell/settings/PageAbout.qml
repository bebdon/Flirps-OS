import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// About Flirps OS: version, hardware, software and credits.
Page {
    id: page
    property var info: ({})

    Process {
        running: true
        command: ["sh", "-c", [
            "echo \"kernel=$(uname -r)\"",
            "echo \"host=$(hostnamectl --static 2>/dev/null || hostname)\"",
            "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//; s/(R)//g; s/(TM)//g; s/ CPU//')\"",
            "echo \"gpu=$(lspci 2>/dev/null | grep -m1 -iE 'vga|3d' | sed 's/.*: //; s/Corporation //; s/ (rev.*//')\"",
            "echo \"ram=$(awk '/MemTotal/ {printf \"%.1f GB\", $2/1048576}' /proc/meminfo)\"",
            "echo \"disk=$(df -h / | awk 'NR==2 {print $3\" / \"$2\" used\"}')\"",
            "echo \"display=$(hyprctl monitors -j | jq -r '.[0] | \"\\(.width)x\\(.height) @ \\(.refreshRate|floor) Hz, scale \\(.scale)\"')\"",
            "echo \"hyprland=$(hyprctl version -j | jq -r .tag)\"",
            "echo \"quickshell=$(qs --version | awk '{print $2}')\"",
            "echo \"base=$(. /usr/lib/os-release; echo $PRETTY_NAME) (rolling)\"",
            "echo \"packages=$(pacman -Qq | wc -l)\"",
            "echo \"uptime=$(uptime -p | sed 's/^up //')\""
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const l of this.text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); }
                page.info = o;
            }
        }
    }

    // ---- hero ----
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 190
        radius: 24
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.primaryContainer }
            GradientStop { position: 1; color: Theme.surfaceLow }
        }
        Row {
            anchors.left: parent.left; anchors.leftMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            spacing: 26
            Logo { size: 112; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                SText { text: Brand.name; font.pixelSize: 40; font.weight: Font.Black; color: Theme.fgPrimaryContainer }
                SText { text: "Version " + Brand.version + " “" + Brand.codename + "”"; font.pixelSize: 15; color: Theme.fgPrimaryContainer }
                SText { text: Brand.tagline; font.pixelSize: 13; color: Theme.fgPrimaryContainer; opacity: 0.75 }
            }
        }
    }

    SectionTitle { text: "This computer" }
    Repeater {
        model: [
            { k: "host", label: "Device name", icon: 0xF0322 },
            { k: "cpu", label: "Processor", icon: 0xF0EE0 },
            { k: "gpu", label: "Graphics", icon: 0xF08AE },
            { k: "ram", label: "Memory", icon: 0xF035B },
            { k: "disk", label: "Storage", icon: 0xF02CA },
            { k: "display", label: "Display", icon: 0xF0379 },
            { k: "uptime", label: "Uptime", icon: 0xF051B }
        ]
        OptionRow {
            required property var modelData
            icon: modelData.icon; title: modelData.label
            SText { text: page.info[parent.parent.modelData.k] || "…"; dim: true; width: Math.min(implicitWidth, 420); horizontalAlignment: Text.AlignRight }
        }
    }

    SectionTitle { text: "Software" }
    Repeater {
        model: [
            { k: "base", label: "Based on", icon: 0xF08C7 },
            { k: "kernel", label: "Kernel", icon: 0xF033D },
            { k: "hyprland", label: "Hyprland", icon: 0xF05AF },
            { k: "quickshell", label: "Quickshell", icon: 0xF0493 },
            { k: "packages", label: "Installed packages", icon: 0xF03D6 }
        ]
        OptionRow {
            required property var modelData
            icon: modelData.icon; title: modelData.label
            SText { text: page.info[parent.parent.modelData.k] || "…"; dim: true }
        }
    }

    SectionTitle { text: "Credits" }
    OptionRow {
        icon: 0xF02D1; title: "Serpantinum by ilyamiro"
        description: "Inspiration for the settings layout, the wallpaper carousel, and the calculator, converter and emoji data (GNU AGPL-3.0)."
        PillButton { text: "GitHub"; filled: false; color: Theme.surfaceHigh; onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/ilyamiro/serpantinum"]) }
    }
    OptionRow {
        icon: 0xF03D8; title: "matugen, awww, waybar, swaync, nwg-dock, hypridle"
        description: "Colours from your wallpaper, wallpaper transitions, bar, notifications, dock and idle handling."
    }
}
