import QtQuick
import QtQuick.Layouts

Page {
    SectionTitle { text: "Waybar" }
    OptionRow {
        icon: 0xF056E; title: "Position"
        Dropdown {
            value: Backend.get("bar", "position", "top")
            options: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
            onPicked: v => Backend.set("bar", "position", v)
        }
    }
    OptionRow {
        icon: 0xF056E; title: "Height"
        ValueSlider { from: 24; to: 60; suffix: "px"; value: Backend.get("bar", "height", 36); onCommitted: v => Backend.set("bar", "height", v) }
    }
    OptionRow {
        icon: 0xF056E; title: "Margin"; description: "Gap between bar and screen edge"
        ValueSlider { from: 0; to: 24; suffix: "px"; value: Backend.get("bar", "margin", 6); onCommitted: v => Backend.set("bar", "margin", v) }
    }
}
