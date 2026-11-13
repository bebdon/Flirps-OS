import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

// Quick settings (click waybar's wifi / bluetooth / volume / battery icons).
BarPopup {
    id: root
    ns: "qs-quicksettings"
    align: "right"
    cardWidth: 440
    signal openPower()
    signal openMedia()

    property string expandedList: ""     // "", "wifi", "bt", "audio"
    property string uptime: ""
    property string pwTarget: ""          // network awaiting a password
    property string pwError: ""

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) || null
    readonly property var wifiNets: wifiDev ? wifiDev.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []
    readonly property var wifiCurrent: wifiNets.find(n => n.connected) || null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDevices: bt ? bt.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)) : []
    readonly property var btConnected: btDevices.filter(d => d.connected)
    readonly property var battery: UPower.displayDevice

    onOpened: {
        Backend.refresh();
        Brightness.refresh();
        uptimeFile.reload();
        expandedList = "";
        pwTarget = "";
    }
    onShownChanged: {
        if (wifiDev) wifiDev.scannerEnabled = shown && expandedList === "wifi";
        if (bt && !shown) bt.discovering = false;
    }
    onExpandedListChanged: {
        if (wifiDev) wifiDev.scannerEnabled = shown && expandedList === "wifi";
        if (bt && bt.enabled) bt.discovering = shown && expandedList === "bt";
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = (d ? d + "d " : "") + (h ? h + "h " : "") + m + "m";
        }
    }

    function fmtTime(sec) {
        if (!sec || sec <= 0) return "";
        const h = Math.floor(sec / 3600), m = Math.round(sec % 3600 / 60);
        return h ? h + "h " + m + "m" : m + "m";
    }
    function wifiIcon(s) { return s > 0.75 ? 0xF0928 : s > 0.5 ? 0xF0925 : s > 0.25 ? 0xF0922 : 0xF091F; }

    ColumnLayout {
        width: parent.width
        spacing: 12

        // ---- header ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4; Layout.rightMargin: 0
            spacing: 10
            Rectangle {
                width: 46; height: 46; radius: 23
                color: Theme.primaryContainer
                SText { anchors.centerIn: parent; text: Quickshell.env("USER").slice(0, 1).toUpperCase(); font.pixelSize: 20; font.weight: Font.Bold; color: Theme.fgPrimaryContainer }
            }
            Column {
                Layout.fillWidth: true
                SText { text: Quickshell.env("USER"); font.pixelSize: 15; font.weight: Font.Bold }
                SText {
                    text: {
                        let t = "up " + root.uptime;
                        if (root.battery && root.battery.isLaptopBattery) {
                            const p = Math.round(root.battery.percentage * 100);
                            const charging = root.battery.state === UPowerDeviceState.Charging;
                            const left = charging ? root.fmtTime(root.battery.timeToFull) : root.fmtTime(root.battery.timeToEmpty);
                            t += "  ·  " + p + "%" + (charging ? " charging" : "") + (left ? " · " + left + (charging ? " to full" : " left") : "");
                        }
                        return t;
                    }
                    dim: true; font.pixelSize: 11
                }
            }
            Repeater {
                model: [
                    { icon: 0xF0493, act: () => { root.close(); Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/settings"]); } },
                    { icon: 0xF033E, act: () => { root.close(); Quickshell.execDetached(["loginctl", "lock-session"]); } },
                    { icon: 0xF0425, act: () => root.openPower() }
                ]
                Rectangle {
                    required property var modelData
                    width: 42; height: 42; radius: 21
                    color: hb.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                    Icon { anchors.centerIn: parent; code: parent.modelData.icon; size: 18 }
                    MouseArea { id: hb; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.act() }
                }
            }
        }

        // ---- tiles ----
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8; rowSpacing: 8

            QsTile {
                Layout.fillWidth: true
                icon: Networking.wifiEnabled ? 0xF0928 : 0xF092E
                title: "Wi-Fi"
                subtitle: !Networking.wifiEnabled ? "Off" : root.wifiCurrent ? root.wifiCurrent.name : "Not connected"
                on: Networking.wifiEnabled
                expandable: true
                expanded: root.expandedList === "wifi"
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                onExpandClicked: root.expandedList = root.expandedList === "wifi" ? "" : "wifi"
            }
            QsTile {
                Layout.fillWidth: true
                icon: !root.bt || !root.bt.enabled ? 0xF00B2 : root.btConnected.length ? 0xF00B1 : 0xF00AF
                title: "Bluetooth"
                subtitle: !root.bt ? "No adapter" : !root.bt.enabled ? "Off" : root.btConnected.length ? root.btConnected.map(d => d.name).join(", ") : "On"
                on: !!root.bt && root.bt.enabled
                expandable: true
                expanded: root.expandedList === "bt"
                onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                onExpandClicked: root.expandedList = root.expandedList === "bt" ? "" : "bt"
            }
            QsTile {
                Layout.fillWidth: true
                icon: on ? 0xF009B : 0xF009A
                title: "Do not disturb"
                subtitle: on ? "On" : "Off"
                on: Backend.get("notif", "dnd", false)
                onClicked: Backend.set("notif", "dnd", !on)
            }
            QsTile {
                Layout.fillWidth: true
                icon: 0xF0594
                title: "Night light"
                subtitle: on ? Backend.get("display", "nightlight_temp", 4000) + "K" : "Off"
                on: Backend.get("display", "nightlight", false)
                onClicked: Backend.set("display", "nightlight", !on)
            }
            QsTile {
                Layout.fillWidth: true
                icon: 0xF0176
                title: "Caffeine"
                subtitle: on ? "Staying awake" : "Off"
                on: !Backend.get("idle", "enabled", true)
                onClicked: Backend.set("idle", "enabled", on)
            }
            QsTile {
                Layout.fillWidth: true
                readonly property string p: Backend.get("display", "power", "balanced")
                readonly property var order: ["power-saver", "balanced", "performance"]
                icon: p === "power-saver" ? 0xF032A : p === "performance" ? 0xF0241 : 0xF00E0
                title: "Power mode"
                subtitle: p === "power-saver" ? "Saver" : p === "performance" ? "Performance" : "Balanced"
                on: p !== "balanced"
                onClicked: Backend.set("display", "power", order[(order.indexOf(p) + 1) % 3])
            }
        }

        // ---- wifi list ----
        Rectangle {
            visible: root.expandedList === "wifi"
            Layout.fillWidth: true
            Layout.preferredHeight: wifiCol.implicitHeight + 16
            radius: 20
            color: Theme.surfaceLow

            Column {
                id: wifiCol
                x: 8; y: 8
                width: parent.width - 16
                spacing: 2

                SText {
                    visible: !Networking.wifiEnabled
                    width: parent.width; padding: 12
                    text: "Wi-Fi is off"; dim: true
                }
                Repeater {
                    model: Networking.wifiEnabled ? root.wifiNets.slice(0, 8) : []
                    Column {
                        id: netRow
                        required property var modelData
                        readonly property bool secure: modelData.security !== WifiSecurityType.Open
                        width: wifiCol.width
                        Rectangle {
                            width: parent.width; height: 46; radius: 23
                            color: netRow.modelData.connected ? Theme.secondaryContainer
                                 : nm.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                            Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; code: root.wifiIcon(netRow.modelData.signalStrength); size: 18 }
                            SText {
                                x: 44; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 100
                                text: netRow.modelData.name
                                font.weight: netRow.modelData.connected ? Font.Bold : Font.Normal
                            }
                            SText {
                                anchors.right: parent.right; anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: netRow.modelData.stateChanging ? "…" : netRow.modelData.connected ? "Connected" : netRow.secure ? String.fromCodePoint(0xF033E) : ""
                                dim: true; font.pixelSize: 11
                            }
                            MouseArea {
                                id: nm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const n = netRow.modelData;
                                    if (n.connected) n.disconnect();
                                    else if (n.known || !netRow.secure) n.connect();
                                    else { root.pwTarget = n.name; root.pwError = ""; }
                                }
                            }
                        }
                        // password entry for new secured networks
                        Rectangle {
                            visible: root.pwTarget === netRow.modelData.name
                            width: parent.width; height: 46; radius: 23
                            color: Theme.surfaceHigh
                            border.width: root.pwError ? 1 : 0; border.color: Theme.error
                            onVisibleChanged: if (visible) pw.forceActiveFocus()
                            TextInput {
                                id: pw
                                anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 60
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                font.family: Theme.font; font.pixelSize: 14
                                color: Theme.text
                                Keys.onEscapePressed: root.pwTarget = ""
                                Keys.onReturnPressed: { netRow.modelData.connectWithPsk(text); text = ""; root.pwTarget = ""; }
                                SText { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: root.pwError || "Password, then Enter"; dim: !root.pwError; color: root.pwError ? Theme.error : Theme.subtext }
                            }
                            Connections {
                                target: netRow.modelData
                                function onConnectionFailed(reason) { root.pwTarget = netRow.modelData.name; root.pwError = "Couldn't connect, check the password"; }
                            }
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 40; radius: 20
                    color: netSettingsMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                    SText { anchors.centerIn: parent; text: "Advanced network settings…"; color: Theme.primary; font.pixelSize: 12 }
                    MouseArea { id: netSettingsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.close(); Quickshell.execDetached(["nm-connection-editor"]); } }
                }
            }
        }

        // ---- bluetooth list ----
        Rectangle {
            visible: root.expandedList === "bt"
            Layout.fillWidth: true
            Layout.preferredHeight: btCol.implicitHeight + 16
            radius: 20
            color: Theme.surfaceLow

            Column {
                id: btCol
                x: 8; y: 8
                width: parent.width - 16
                spacing: 2

                SText {
                    visible: !root.bt || !root.bt.enabled || root.btDevices.length === 0
                    width: parent.width; padding: 12
                    text: !root.bt || !root.bt.enabled ? "Bluetooth is off" : "Searching for devices…"
                    dim: true
                }
                Repeater {
                    model: root.bt && root.bt.enabled ? root.btDevices.filter(d => d.paired || !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name)).slice(0, 8) : []
                    Rectangle {
                        id: devRow
                        required property var modelData
                        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing
                        width: btCol.width; height: 46; radius: 23
                        color: modelData.connected ? Theme.secondaryContainer
                             : bm.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                        Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; code: devRow.modelData.connected ? 0xF00B1 : 0xF00AF; size: 18 }
                        SText {
                            x: 44; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 150
                            text: devRow.modelData.name
                            font.weight: devRow.modelData.connected ? Font.Bold : Font.Normal
                        }
                        SText {
                            anchors.right: forget.visible ? forget.left : parent.right
                            anchors.rightMargin: forget.visible ? 6 : 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: devRow.busy ? "…"
                                : devRow.modelData.connected ? (devRow.modelData.batteryAvailable ? Math.round(devRow.modelData.battery * 100) + "% · " : "") + "Connected"
                                : devRow.modelData.paired ? "Paired" : "Pair"
                            dim: true; font.pixelSize: 11
                        }
                        MouseArea {
                            id: bm
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const d = devRow.modelData;
                                if (d.connected) d.disconnect();
                                else if (d.paired) d.connect();
                                else { d.trusted = true; d.pair(); }
                            }
                        }
                        // forget a paired device (what blueman was needed for)
                        Rectangle {
                            id: forget
                            visible: devRow.modelData.paired && (bm.containsMouse || fm.containsMouse)
                            anchors.right: parent.right; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34; height: 34; radius: 17
                            color: fm.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                            Icon { anchors.centerIn: parent; code: 0xF0A7A; size: 16; color: fm.containsMouse ? Theme.error : Theme.subtext }
                            MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: devRow.modelData.forget() }
                        }
                    }
                }
                SText {
                    visible: !!root.bt && root.bt.enabled && root.btDevices.length > 0
                    width: parent.width; padding: 10
                    horizontalAlignment: Text.AlignHCenter
                    text: "Searching nearby · new devices appear here"
                    dim: true; font.pixelSize: 11
                }
            }
        }

        // ---- sliders ----
        QsSlider {
            Layout.fillWidth: true
            icon: Audio.muted ? 0xF075F : Audio.volume > 0.5 ? 0xF057E : Audio.volume > 0.15 ? 0xF0580 : 0xF057F
            value: Audio.volume
            muted: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
            expandable: true
            expanded: root.expandedList === "audio"
            onExpandClicked: root.expandedList = root.expandedList === "audio" ? "" : "audio"
        }

        // ---- sound list: output, input, per-app volume ----
        Rectangle {
            visible: root.expandedList === "audio"
            Layout.fillWidth: true
            Layout.preferredHeight: audioCol.implicitHeight + 16
            radius: 20
            color: Theme.surfaceLow

            Column {
                id: audioCol
                x: 8; y: 8
                width: parent.width - 16
                spacing: 2

                Repeater {
                    model: [
                        { title: "Output", list: Audio.outputs, current: Audio.sink, icon: 0xF04C3, use: n => Audio.useOutput(n) },
                        { title: "Input", list: Audio.inputs, current: Audio.source, icon: 0xF036C, use: n => Audio.useInput(n) }
                    ]
                    Column {
                        id: sect
                        required property var modelData
                        width: audioCol.width
                        visible: modelData.list.length > 0
                        SText { text: sect.modelData.title; dim: true; font.pixelSize: 11; leftPadding: 14; topPadding: 6; bottomPadding: 4 }
                        Repeater {
                            model: sect.modelData.list
                            Rectangle {
                                id: devItem
                                required property var modelData
                                readonly property bool current: sect.modelData.current === modelData
                                width: sect.width; height: 46; radius: 23
                                color: current ? Theme.secondaryContainer
                                     : dm.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                                Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; code: sect.modelData.icon; size: 18 }
                                SText {
                                    x: 44; anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 58
                                    text: Audio.deviceName(devItem.modelData)
                                    font.weight: devItem.current ? Font.Bold : Font.Normal
                                }
                                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sect.modelData.use(devItem.modelData) }
                            }
                        }
                    }
                }

                SText {
                    text: "Apps"; dim: true; font.pixelSize: 11; leftPadding: 14; topPadding: 6; bottomPadding: 4
                }
                SText {
                    visible: Audio.apps.length === 0
                    width: parent.width; leftPadding: 14; bottomPadding: 8
                    text: "No apps are playing sound"; dim: true
                }
                Repeater {
                    model: Audio.apps
                    Column {
                        id: appItem
                        required property var modelData
                        width: audioCol.width
                        spacing: 2
                        SText { text: Audio.appName(appItem.modelData); width: parent.width; leftPadding: 14; font.pixelSize: 12 }
                        QsSlider {
                            width: parent.width
                            icon: appItem.modelData.audio && appItem.modelData.audio.muted ? 0xF075F : 0xF057E
                            value: appItem.modelData.audio ? appItem.modelData.audio.volume : 0
                            muted: appItem.modelData.audio ? appItem.modelData.audio.muted : false
                            onMoved: v => { if (appItem.modelData.audio) { appItem.modelData.audio.muted = false; appItem.modelData.audio.volume = v; } }
                            onIconClicked: if (appItem.modelData.audio) appItem.modelData.audio.muted = !appItem.modelData.audio.muted
                        }
                    }
                }
            }
        }
        QsSlider {
            Layout.fillWidth: true
            visible: !!Audio.source
            icon: Audio.micMuted ? 0xF036D : 0xF036C
            value: Audio.micVolume
            muted: Audio.micMuted
            onMoved: v => Audio.setMic(v)
            onIconClicked: Audio.toggleMic()
        }
        QsSlider {
            Layout.fillWidth: true
            icon: 0xF00DF
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }

        // ---- media ----
        Rectangle {
            visible: Media.active
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            radius: 22
            color: Theme.surfaceHigh

            RoundedImage {
                id: art
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 56; height: 56; radius: 14
                source: Media.art
                visible: Media.art !== ""
            }
            Rectangle {
                visible: Media.art === ""
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 56; height: 56; radius: 14
                color: Theme.surfaceHighest
                Icon { anchors.centerIn: parent; code: 0xF075A; size: 24 }
            }
            Column {
                x: 78; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 78 - ctrls.width - 16
                SText { width: parent.width; text: Media.title; font.weight: Font.Bold }
                SText { width: parent.width; text: Media.artist; dim: true; font.pixelSize: 12 }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.openMedia() }
            Row {
                id: ctrls
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Repeater {
                    model: [
                        { icon: 0xF04AE, act: () => Media.player.previous() },
                        { icon: Media.playing ? 0xF03E4 : 0xF040A, act: () => Media.player.togglePlaying(), main: true },
                        { icon: 0xF04AD, act: () => Media.player.next() }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 38; height: 38; radius: modelData.main ? 14 : 19
                        color: modelData.main ? Theme.primary : (mb.containsMouse ? Theme.surfaceHighest : "transparent")
                        Icon { anchors.centerIn: parent; code: parent.modelData.icon; size: 18; color: parent.modelData.main ? Theme.fgPrimary : Theme.text }
                        MouseArea { id: mb; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.act() }
                    }
                }
            }
        }

        // ---- screenshot ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: [
                    { label: "Area", icon: 0xF0293, args: [] },
                    { label: "Screen", icon: 0xF0379, args: ["--full"] },
                    { label: "Edit", icon: 0xF03EB, args: ["--edit"] },
                    { label: "Text", icon: 0xF0F5A, args: ["--ocr"] }
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 40; radius: 20
                    color: sm.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Icon { code: parent.parent.modelData.icon; size: 15 }
                        SText { text: parent.parent.modelData.label; font.pixelSize: 12 }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.close();
                            Quickshell.execDetached(["sh", "-c", "sleep 0.35; exec \"$0\" \"$@\"", Quickshell.env("HOME") + "/.local/bin/screenshot"].concat(parent.modelData.args));
                        }
                    }
                }
            }
        }
    }
}
