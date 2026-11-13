import QtQuick
import QtQuick.Layouts

Page {
    SectionTitle { text: "Mouse & touchpad" }
    OptionRow {
        icon: 0xF037D; title: "Pointer acceleration"
        Dropdown {
            value: Backend.get("hypr", "accel", "flat")
            options: [{ label: "Flat", value: "flat" }, { label: "Adaptive", value: "adaptive" }]
            onPicked: v => Backend.set("hypr", "accel", v)
        }
    }
    OptionRow {
        icon: 0xF037D; title: "Natural scrolling"; description: "Touchpad content follows your fingers"
        Toggle { checked: Backend.get("hypr", "natural_scroll", true); onToggled: v => Backend.set("hypr", "natural_scroll", v) }
    }
}
