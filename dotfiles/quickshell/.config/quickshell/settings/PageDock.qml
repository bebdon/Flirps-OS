import QtQuick
import QtQuick.Layouts

Page {
    SectionTitle { text: "nwg-dock" }
    OptionRow {
        icon: 0xF003B; title: "Behaviour"
        Dropdown {
            value: Backend.get("dock", "mode", "autohide")
            options: [{ label: "Autohide", value: "autohide" }, { label: "Always visible", value: "resident" }]
            onPicked: v => Backend.set("dock", "mode", v)
        }
    }
    OptionRow {
        icon: 0xF003B; title: "Position"
        Dropdown {
            value: Backend.get("dock", "position", "bottom")
            options: ["bottom", "left", "right", "top"].map(v => ({ label: v[0].toUpperCase() + v.slice(1), value: v }))
            onPicked: v => Backend.set("dock", "position", v)
        }
    }
    OptionRow {
        icon: 0xF003B; title: "Icon size"
        ValueSlider { from: 24; to: 72; suffix: "px"; value: Backend.get("dock", "size", 44); onCommitted: v => Backend.set("dock", "size", v) }
    }
}
