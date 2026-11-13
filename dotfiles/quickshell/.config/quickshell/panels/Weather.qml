pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Open-Meteo forecast (no API key). Location/units from panels/location.json.
// Cached in ~/.cache/quickshell/weather.json and refreshed every 15 minutes.
Singleton {
    id: root
    property var data: null
    property bool loading: false
    readonly property bool ready: data !== null && data.current !== undefined
    readonly property string unitSym: loc.unit === "fahrenheit" ? "°F" : "°C"
    readonly property string place: loc.name

    readonly property var current: ready ? data.current : null
    readonly property var daily: ready ? data.daily : null
    readonly property var hourly: ready ? data.hourly : null

    function refresh() {
        if (fetcher.running) return;
        loading = true;
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + loc.lat + "&longitude=" + loc.lon
            + "&timezone=" + encodeURIComponent(loc.tz || "auto")
            + "&current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max"
            + "&forecast_days=6&temperature_unit=" + (loc.unit || "celsius");
        fetcher.command = ["curl", "-sf", "--max-time", "15", url];
        fetcher.running = true;
    }
    function refreshIfStale() {
        if (!ready || !data.fetchedAt || Date.now() - data.fetchedAt > 15 * 60 * 1000) refresh();
    }

    // Weather code -> [day icon, night icon, label]
    function info(code) {
        const c = Number(code);
        if (c === 0) return [0xF0599, 0xF0594, "Clear"];
        if (c <= 2) return [0xF0595, 0xF0F31, c === 1 ? "Mostly clear" : "Partly cloudy"];
        if (c === 3) return [0xF0590, 0xF0590, "Cloudy"];
        if (c <= 48) return [0xF0591, 0xF0591, "Fog"];
        if (c <= 57) return [0xF0597, 0xF0597, "Drizzle"];
        if (c <= 67) return [0xF0597, 0xF0597, c >= 65 ? "Heavy rain" : "Rain"];
        if (c <= 77) return [0xF0598, 0xF0598, "Snow"];
        if (c <= 82) return [0xF0596, 0xF0596, "Showers"];
        if (c <= 86) return [0xF0598, 0xF0598, "Snow showers"];
        return [0xF0593, 0xF0593, "Thunderstorm"];
    }
    function icon(code, isDay) { const i = info(code); return isDay === 0 ? i[1] : i[0]; }
    function label(code) { return info(code)[2]; }

    // index of the current hour in the hourly arrays
    function hourIndex() {
        if (!ready) return 0;
        const now = current.time.slice(0, 13);
        const i = hourly.time.findIndex(t => t.slice(0, 13) === now);
        return Math.max(0, i);
    }

    FileView {
        id: locFile
        path: Quickshell.shellDir + "/location.json"
        watchChanges: true
        property bool seen: false
        onFileChanged: reload()
        onLoaded: { if (seen) root.refresh(); seen = true; }   // refetch only when the location changes
        JsonAdapter {
            id: loc
            property string name: "London"
            property real lat: 51.51
            property real lon: -0.13
            property string tz: "Europe/London"
            property string unit: "celsius"
        }
    }

    FileView {
        id: cache
        path: Quickshell.env("HOME") + "/.cache/quickshell/weather.json"
        printErrors: false
        onLoaded: {
            try { root.data = JSON.parse(text()); } catch (e) {}
            root.refreshIfStale();
        }
        onLoadFailed: root.refresh()
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const d = JSON.parse(this.text);
                    if (!d.current) return;
                    d.fetchedAt = Date.now();
                    root.data = d;
                    cache.setText(JSON.stringify(d));
                } catch (e) { console.warn("weather: bad response"); }
            }
        }
        onExited: code => { if (code !== 0) root.loading = false; }
    }

    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
}
