import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Page {
    SectionTitle { text: "Screen" }
    OptionRow {
        icon: 0xF0379; title: "Scale"; description: "Applies to all monitors"
        Dropdown {
            value: Backend.get("display", "scale", 1.6)
            options: [1, 1.25, 1.333333, 1.5, 1.6, 1.75, 2].map(v => ({ label: (Math.round(v * 100)) + "%", value: v }))
            onPicked: v => Backend.set("display", "scale", v)
        }
    }

    SectionTitle { text: "Night light" }
    OptionRow {
        icon: 0xF0594; title: "Night light"; description: "Warmer colours with hyprsunset"
        Toggle { checked: Backend.get("display", "nightlight", false); onToggled: v => Backend.set("display", "nightlight", v) }
    }
    OptionRow {
        icon: 0xF0594; title: "Temperature"
        ValueSlider { from: 2500; to: 6000; stepSize: 100; suffix: "K"; value: Backend.get("display", "nightlight_temp", 4000); onCommitted: v => Backend.set("display", "nightlight_temp", v) }
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

    // ---- weather (used by the clock dashboard and desktop widgets) ----
    SectionTitle { text: "Weather" }

    FileView {
        id: locFile
        path: Quickshell.env("HOME") + "/.config/quickshell/panels/location.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: loc
            property string name: "London"
            property real lat: 51.51
            property real lon: -0.13
            property string tz: "Europe/London"
            property string unit: "celsius"
        }
    }
    Process {
        id: geo
        property var results: []
        stdout: StdioCollector {
            onStreamFinished: { try { geo.results = JSON.parse(this.text).results || []; } catch (e) { geo.results = []; } }
        }
    }

    OptionRow {
        icon: 0xF034E; title: "Location"; description: loc.name + "  (" + loc.lat.toFixed(2) + ", " + loc.lon.toFixed(2) + ")"
        Rectangle {
            width: 260; height: 44; radius: 22
            color: Theme.surfaceHigh
            TextInput {
                id: cityInput
                anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
                verticalAlignment: TextInput.AlignVCenter
                font.family: Theme.font; font.pixelSize: 14
                color: Theme.text
                clip: true
                onAccepted: {
                    if (!text.trim()) return;
                    geo.command = ["curl", "-sf", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?count=5&name=" + encodeURIComponent(text.trim())];
                    geo.running = true;
                }
                SText { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: "Search a city, Enter"; dim: true }
            }
        }
    }
    Repeater {
        model: geo.results
        OptionRow {
            required property var modelData
            icon: 0xF034E
            title: modelData.name
            description: [modelData.admin1, modelData.country].filter(x => x).join(", ")
            PillButton {
                text: "Use"
                onClicked: {
                    loc.name = parent.parent.modelData.name;
                    loc.lat = Math.round(parent.parent.modelData.latitude * 100) / 100;
                    loc.lon = Math.round(parent.parent.modelData.longitude * 100) / 100;
                    loc.tz = parent.parent.modelData.timezone || "auto";
                    locFile.writeAdapter();
                    geo.results = [];
                    cityInput.text = "";
                }
            }
        }
    }
    OptionRow {
        icon: 0xF050F; title: "Temperature units"
        Dropdown {
            value: loc.unit
            options: [{ label: "Celsius (°C)", value: "celsius" }, { label: "Fahrenheit (°F)", value: "fahrenheit" }]
            onPicked: v => { loc.unit = v; locFile.writeAdapter(); }
        }
    }
}
