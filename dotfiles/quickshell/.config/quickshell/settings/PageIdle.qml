import QtQuick
import QtQuick.Layouts

Page {

    SectionTitle { text: "hypridle" }
    OptionRow {
        icon: 0xF04B2; title: "Idle actions"; description: "Turn off to keep the screen awake (caffeine)"
        Toggle { checked: Backend.get("idle", "enabled", true); onToggled: v => Backend.set("idle", "enabled", v) }
    }

    SectionTitle { text: "Timeouts (seconds)" }
    OptionRow {
        icon: 0xF00DE; title: "Dim screen"
        ValueSlider { from: 30; to: 1800; stepSize: 30; value: Backend.get("idle", "dim", 150); onCommitted: v => Backend.set("idle", "dim", v) }
    }
    OptionRow {
        icon: 0xF033E; title: "Lock"
        ValueSlider { from: 60; to: 3600; stepSize: 30; value: Backend.get("idle", "lock", 300); onCommitted: v => Backend.set("idle", "lock", v) }
    }
    OptionRow {
        icon: 0xF0379; title: "Screen off"
        ValueSlider { from: 60; to: 3600; stepSize: 30; value: Backend.get("idle", "dpms", 450); onCommitted: v => Backend.set("idle", "dpms", v) }
    }
    OptionRow {
        icon: 0xF04B2; title: "Suspend"
        ValueSlider { from: 120; to: 7200; stepSize: 60; value: Backend.get("idle", "suspend", 600); onCommitted: v => Backend.set("idle", "suspend", v) }
    }
}
