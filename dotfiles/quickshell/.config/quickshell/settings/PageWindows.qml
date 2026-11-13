import QtQuick
import QtQuick.Layouts

Page {
    SectionTitle { text: "Layout" }
    OptionRow {
        icon: 0xF05AF; title: "Inner gaps"; description: "Space between windows"
        ValueSlider { from: 0; to: 30; value: Backend.get("hypr", "gaps_in", 4); suffix: "px"; onCommitted: v => Backend.set("hypr", "gaps_in", v) }
    }
    OptionRow {
        icon: 0xF05AF; title: "Outer gaps"; description: "Space between windows and screen edge"
        ValueSlider { from: 0; to: 40; value: Backend.get("hypr", "gaps_out", 6); suffix: "px"; onCommitted: v => Backend.set("hypr", "gaps_out", v) }
    }
    OptionRow {
        icon: 0xF0607; title: "Corner rounding"
        ValueSlider { from: 0; to: 30; value: Backend.get("hypr", "rounding", 12); suffix: "px"; onCommitted: v => Backend.set("hypr", "rounding", v) }
    }
    OptionRow {
        icon: 0xF0493; title: "Border size"
        ValueSlider { from: 0; to: 6; value: Backend.get("hypr", "border_size", 0); suffix: "px"; onCommitted: v => Backend.set("hypr", "border_size", v) }
    }

    SectionTitle { text: "Motion" }
    OptionRow {
        icon: 0xF0E49; title: "Window animations"; description: "Springy open/close and sliding workspaces. Off = reduced motion."
        Dropdown {
            value: Backend.get("hypr", "anim", "normal")
            options: [{ label: "Fast", value: "fast" }, { label: "Normal", value: "normal" }, { label: "Relaxed", value: "relaxed" }, { label: "Off", value: "off" }]
            onPicked: v => Backend.set("hypr", "anim", v)
        }
    }

    SectionTitle { text: "Effects" }
    OptionRow {
        icon: 0xF05AF; title: "Active window opacity"
        ValueSlider { from: 0.5; to: 1; stepSize: 0.01; decimals: 2; value: Backend.get("hypr", "active_opacity", 1); onCommitted: v => Backend.set("hypr", "active_opacity", v) }
    }
    OptionRow {
        icon: 0xF05AF; title: "Inactive window opacity"
        ValueSlider { from: 0.5; to: 1; stepSize: 0.01; decimals: 2; value: Backend.get("hypr", "inactive_opacity", 1); onCommitted: v => Backend.set("hypr", "inactive_opacity", v) }
    }
    OptionRow {
        icon: 0xF00B5; title: "Blur"; description: "Blur behind transparent windows"
        Toggle { checked: Backend.get("hypr", "blur", true); onToggled: v => Backend.set("hypr", "blur", v) }
    }
    OptionRow {
        visible: Backend.get("hypr", "blur", true)
        icon: 0xF00B5; title: "Blur size"
        ValueSlider { from: 1; to: 20; value: Backend.get("hypr", "blur_size", 8); onCommitted: v => Backend.set("hypr", "blur_size", v) }
    }
    OptionRow {
        visible: Backend.get("hypr", "blur", true)
        icon: 0xF00B5; title: "Blur passes"; description: "Most expensive effect at 3200×1800. 2 passes looks almost the same and saves battery."
        ValueSlider { from: 1; to: 6; value: Backend.get("hypr", "blur_passes", 3); onCommitted: v => Backend.set("hypr", "blur_passes", v) }
    }
    OptionRow {
        icon: 0xF05AF; title: "Shadows"
        Toggle { checked: Backend.get("hypr", "shadow", true); onToggled: v => Backend.set("hypr", "shadow", v) }
    }
}
