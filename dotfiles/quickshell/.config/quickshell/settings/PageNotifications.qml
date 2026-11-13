import QtQuick
import QtQuick.Layouts

Page {
    SectionTitle { text: "Behaviour" }
    OptionRow {
        icon: 0xF009B; title: "Do not disturb"
        Toggle { checked: Backend.get("notif", "dnd", false); onToggled: v => Backend.set("notif", "dnd", v) }
    }
    OptionRow {
        icon: 0xF057E; title: "Notification sound"
        Toggle { checked: Backend.get("notif", "sound", true); onToggled: v => Backend.set("notif", "sound", v) }
    }
    OptionRow {
        icon: 0xF051B; title: "Timeout"; description: "How long popups stay on screen"
        ValueSlider { from: 1; to: 20; suffix: "s"; value: Backend.get("notif", "timeout", 6); onCommitted: v => Backend.set("notif", "timeout", v) }
    }

    SectionTitle { text: "Popup placement" }
    OptionRow {
        icon: 0xF009A; title: "Horizontal"
        Dropdown {
            value: Backend.get("notif", "x", "right")
            options: [{ label: "Left", value: "left" }, { label: "Center", value: "center" }, { label: "Right", value: "right" }]
            onPicked: v => Backend.set("notif", "x", v)
        }
    }
    OptionRow {
        icon: 0xF009A; title: "Vertical"
        Dropdown {
            value: Backend.get("notif", "y", "top")
            options: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
            onPicked: v => Backend.set("notif", "y", v)
        }
    }
    OptionRow {
        icon: 0xF009A; title: "Width"
        ValueSlider { from: 280; to: 560; stepSize: 10; suffix: "px"; value: Backend.get("notif", "width", 380); onCommitted: v => Backend.set("notif", "width", v) }
    }
}
