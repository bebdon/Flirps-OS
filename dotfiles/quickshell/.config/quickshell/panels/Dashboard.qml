import QtQuick
import QtQuick.Layouts
import Quickshell

// Calendar + clock + weather (click the clock in the bar).
BarPopup {
    id: root
    ns: "qs-dashboard"
    align: "center"
    cardWidth: 780

    property date now: new Date()
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    property int slideDir: 0

    onOpened: {
        now = new Date();
        viewYear = now.getFullYear();
        viewMonth = now.getMonth();
        Weather.refreshIfStale();
    }

    Timer { interval: 1000; running: root.visible; repeat: true; onTriggered: root.now = new Date() }

    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    function shiftMonth(d) {
        slideDir = d;
        let m = viewMonth + d, y = viewYear;
        if (m < 0) { m = 11; y--; } else if (m > 11) { m = 0; y++; }
        viewMonth = m; viewYear = y;
        monthAnim.restart();
    }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }
    // 6 weeks x 7 days, Monday first
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const offset = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) out.push(new Date(viewYear, viewMonth, 1 - offset + i));
        return out;
    }
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    RowLayout {
        width: parent.width
        spacing: 12

        // ================= left: clock + calendar =================
        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            Layout.minimumHeight: 430
            radius: 20
            color: Theme.surfaceLow

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    spacing: 6
                    SText { text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes()); font.pixelSize: 54; font.weight: Font.Bold; color: Theme.primary }
                    SText { anchors.bottom: parent.bottom; anchors.bottomMargin: 10; text: root.pad(root.now.getSeconds()); font.pixelSize: 20; color: Theme.subtext }
                }
                SText {
                    text: root.dayNames[root.now.getDay()] + ", " + root.now.getDate() + " " + root.monthNames[root.now.getMonth()] + " " + root.now.getFullYear() + "  ·  week " + root.isoWeek(root.now)
                    dim: true; font.pixelSize: 13
                }

                Item { width: 1; height: 4 }

                // month header
                Item {
                    width: parent.width; height: 34
                    SText { anchors.verticalCenter: parent.verticalCenter; text: root.monthNames[root.viewMonth] + " " + root.viewYear; font.pixelSize: 15; font.weight: Font.Bold }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: [{ i: 0xF0141, d: -1 }, { i: 0xF00F6, d: 0 }, { i: 0xF0142, d: 1 }]
                            Rectangle {
                                required property var modelData
                                width: 32; height: 32; radius: 16
                                color: cm.containsMouse ? Theme.surfaceHigh : "transparent"
                                Icon { anchors.centerIn: parent; code: parent.modelData.i; size: 18 }
                                MouseArea {
                                    id: cm
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.modelData.d === 0) { root.viewYear = root.now.getFullYear(); root.viewMonth = root.now.getMonth(); }
                                        else root.shiftMonth(parent.modelData.d);
                                    }
                                }
                            }
                        }
                    }
                }

                // grid
                Item {
                    width: parent.width
                    height: grid.height
                    clip: true

                    Grid {
                        id: grid
                        columns: 8
                        width: parent.width
                        readonly property real cw: width / 8

                        SText { width: grid.cw; height: 26; text: "wk"; dim: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            SText { required property string modelData; width: grid.cw; height: 26; text: modelData; dim: true; font.pixelSize: 11; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }

                        Repeater {
                            model: 48   // 6 rows x (week number + 7 days)
                            Item {
                                id: cell
                                required property int index
                                readonly property bool isWeek: index % 8 === 0
                                readonly property var day: root.cells[Math.floor(index / 8) * 7 + (index % 8) - (isWeek ? 0 : 1)]
                                readonly property bool inMonth: day.getMonth() === root.viewMonth
                                readonly property bool isToday: day.toDateString() === root.now.toDateString()
                                width: grid.cw; height: grid.cw * 0.86

                                Rectangle {
                                    visible: cell.isToday && !cell.isWeek
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height) - 2; height: width; radius: width / 2
                                    color: Theme.primary
                                }
                                SText {
                                    anchors.centerIn: parent
                                    text: cell.isWeek ? root.isoWeek(cell.day) : cell.day.getDate()
                                    font.pixelSize: cell.isWeek ? 10 : 13
                                    font.weight: cell.isToday ? Font.Bold : Font.Normal
                                    color: cell.isToday && !cell.isWeek ? Theme.fgPrimary
                                         : cell.isWeek ? Theme.outline
                                         : cell.inMonth ? ((cell.index % 8) >= 6 ? Theme.tertiary : Theme.text) : Theme.outline
                                    opacity: cell.inMonth || cell.isWeek ? 1 : 0.5
                                }
                            }
                        }
                    }

                    NumberAnimation { id: monthAnim; target: grid; property: "x"; from: root.slideDir * 30; to: 0; duration: 220; easing.type: Easing.OutCubic }
                    WheelHandler { onWheel: e => root.shiftMonth(e.angleDelta.y > 0 ? -1 : 1) }
                }
            }
        }

        // ================= right: weather =================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: weatherCol.implicitHeight + 32
            radius: 20
            color: Theme.surfaceLow

            Column {
                id: weatherCol
                x: 16; y: 16
                width: parent.width - 32
                spacing: 14

                SText {
                    visible: !Weather.ready
                    text: Weather.loading ? "Loading weather…" : "Weather unavailable (offline?)"
                    dim: true
                }

                // current
                Item {
                    visible: Weather.ready
                    width: parent.width; height: 84
                    Icon {
                        id: bigIcon
                        anchors.verticalCenter: parent.verticalCenter
                        code: Weather.ready ? Weather.icon(Weather.current.weather_code, Weather.current.is_day) : 0
                        size: 64
                        color: Theme.primary
                    }
                    Column {
                        anchors.left: bigIcon.right; anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        SText { text: Weather.ready ? Math.round(Weather.current.temperature_2m) + Weather.unitSym : ""; font.pixelSize: 36; font.weight: Font.Bold }
                        SText { text: Weather.ready ? Weather.label(Weather.current.weather_code) + " · feels " + Math.round(Weather.current.apparent_temperature) + "°" : ""; dim: true; font.pixelSize: 12 }
                    }
                    Column {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        SText { anchors.right: parent.right; text: String.fromCodePoint(0xF034E) + " " + Weather.place; font.pixelSize: 13; font.weight: Font.Bold }
                        SText { anchors.right: parent.right; text: Weather.ready ? String.fromCodePoint(0xF058E) + " " + Weather.current.relative_humidity_2m + "%   " + String.fromCodePoint(0xF059D) + " " + Math.round(Weather.current.wind_speed_10m) + " km/h" : ""; dim: true; font.pixelSize: 11 }
                        SText {
                            anchors.right: parent.right
                            text: Weather.ready ? "H " + Math.round(Weather.daily.temperature_2m_max[0]) + "°  L " + Math.round(Weather.daily.temperature_2m_min[0]) + "°" : ""
                            dim: true; font.pixelSize: 11
                        }
                    }
                }

                // hourly strip
                Row {
                    visible: Weather.ready
                    width: parent.width
                    readonly property int start: Weather.hourIndex()
                    Repeater {
                        model: Weather.ready ? 12 : 0
                        Column {
                            required property int index
                            readonly property int i: parent.start + index
                            width: parent.width / 12
                            spacing: 4
                            SText { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Now" : Weather.hourly.time[parent.i].slice(11, 13); dim: true; font.pixelSize: 10 }
                            Icon { anchors.horizontalCenter: parent.horizontalCenter; code: Weather.icon(Weather.hourly.weather_code[parent.i], Weather.hourly.is_day[parent.i]); size: 18 }
                            SText { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(Weather.hourly.temperature_2m[parent.i]) + "°"; font.pixelSize: 12; font.weight: Font.Bold }
                            SText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                readonly property int p: Weather.hourly.precipitation_probability[parent.i]
                                text: p >= 20 ? p + "%" : " "
                                color: Theme.secondary; font.pixelSize: 9
                            }
                        }
                    }
                }

                Rectangle { visible: Weather.ready; width: parent.width; height: 1; color: Theme.outlineVariant }

                // daily
                Column {
                    visible: Weather.ready
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: Weather.ready ? 5 : 0
                        Item {
                            id: dayRow
                            required property int index
                            readonly property real lo: Weather.daily.temperature_2m_min[index + 1]
                            readonly property real hi: Weather.daily.temperature_2m_max[index + 1]
                            readonly property real wkLo: Math.min.apply(null, Weather.daily.temperature_2m_min.slice(1, 6))
                            readonly property real wkHi: Math.max.apply(null, Weather.daily.temperature_2m_max.slice(1, 6))
                            width: parent.width; height: 30
                            SText {
                                width: 56; anchors.verticalCenter: parent.verticalCenter
                                text: index === 0 ? "Tmrw" : root.dayNames[new Date(Weather.daily.time[index + 1]).getDay()]
                                font.pixelSize: 12
                            }
                            Icon { x: 60; anchors.verticalCenter: parent.verticalCenter; code: Weather.icon(Weather.daily.weather_code[index + 1], 1); size: 17 }
                            SText { x: 90; width: 40; anchors.verticalCenter: parent.verticalCenter; text: Math.round(dayRow.lo) + "°"; dim: true; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                            // temperature range bar
                            Rectangle {
                                id: rangeTrack
                                x: 140; width: parent.width - 140 - 90
                                anchors.verticalCenter: parent.verticalCenter
                                height: 6; radius: 3
                                color: Theme.surfaceHighest
                                Rectangle {
                                    readonly property real span: Math.max(1, dayRow.wkHi - dayRow.wkLo)
                                    x: (dayRow.lo - dayRow.wkLo) / span * parent.width
                                    width: Math.max(6, (dayRow.hi - dayRow.lo) / span * parent.width)
                                    height: 6; radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0; color: Theme.secondary }
                                        GradientStop { position: 1; color: Theme.primary }
                                    }
                                }
                            }
                            SText { x: parent.width - 82; width: 36; anchors.verticalCenter: parent.verticalCenter; text: Math.round(dayRow.hi) + "°"; font.pixelSize: 12; font.weight: Font.Bold }
                            SText {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                readonly property int p: Weather.daily.precipitation_probability_max[dayRow.index + 1]
                                text: p >= 20 ? String.fromCodePoint(0xF058C) + p + "%" : ""
                                color: Theme.secondary; font.pixelSize: 10
                            }
                        }
                    }
                }

                Rectangle { visible: Weather.ready; width: parent.width; height: 1; color: Theme.outlineVariant }

                // sunrise / sunset arc
                Item {
                    id: sun
                    visible: Weather.ready
                    width: parent.width; height: 80
                    readonly property real rise: Weather.ready ? new Date(Weather.daily.sunrise[0]).getTime() : 0
                    readonly property real set: Weather.ready ? new Date(Weather.daily.sunset[0]).getTime() : 0
                    readonly property real t: Math.max(0, Math.min(1, (root.now.getTime() - rise) / Math.max(1, set - rise)))
                    readonly property bool up: root.now.getTime() > rise && root.now.getTime() < set
                    function hm(ms) { const d = new Date(ms); return root.pad(d.getHours()) + ":" + root.pad(d.getMinutes()); }

                    Canvas {
                        id: arc
                        anchors.fill: parent
                        anchors.leftMargin: 70; anchors.rightMargin: 70
                        readonly property color line: Theme.outlineVariant
                        readonly property color fill: Theme.primary
                        onLineChanged: requestPaint()
                        Connections { target: root; function onOpened() { arc.requestPaint(); } }
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const w = width, h = height - 8;
                            ctx.lineWidth = 2;
                            ctx.setLineDash([4, 4]);
                            ctx.strokeStyle = line;
                            ctx.beginPath();
                            ctx.moveTo(0, h);
                            ctx.quadraticCurveTo(w / 2, -h * 0.9, w, h);
                            ctx.stroke();
                            ctx.setLineDash([]);
                            ctx.beginPath(); ctx.moveTo(0, h); ctx.lineTo(w, h); ctx.stroke();
                            if (sun.up) {
                                const t = sun.t;
                                const x = 2 * (1 - t) * t * (w / 2) + t * t * w;
                                const y = (1 - t) * (1 - t) * h + 2 * (1 - t) * t * (-h * 0.9) + t * t * h;
                                ctx.fillStyle = fill;
                                ctx.beginPath(); ctx.arc(x, y, 8, 0, Math.PI * 2); ctx.fill();
                            }
                        }
                    }
                    Column {
                        anchors.left: parent.left; anchors.bottom: parent.bottom
                        Icon { code: 0xF059C; size: 18; color: Theme.tertiary }
                        SText { text: sun.hm(sun.rise); font.pixelSize: 11 }
                    }
                    Column {
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        Icon { anchors.right: parent.right; code: 0xF059B; size: 18; color: Theme.tertiary }
                        SText { text: sun.hm(sun.set); font.pixelSize: 11 }
                    }
                    SText {
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                        text: {
                            const n = root.now.getTime();
                            const fmt = ms => { const m = Math.round(ms / 60000); return Math.floor(m / 60) + "h " + (m % 60) + "m"; };
                            return n < sun.rise ? "Sunrise in " + fmt(sun.rise - n) : n < sun.set ? fmt(sun.set - n) + " of daylight left" : "Sun has set";
                        }
                        dim: true; font.pixelSize: 11
                    }
                }
            }
        }
    }
}
