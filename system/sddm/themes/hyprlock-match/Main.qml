// SDDM login screen styled to match ~/.config/hypr/hyprlock.conf.
// Colors and background come from theme.conf, written by ~/.local/bin/sddm-sync.
import QtQuick 2.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.surface || "#1a1112"

    property string fontName: "JetBrainsMono Nerd Font"
    property bool failed: false
    // match Hyprland scale 1.6 on 3200x1800 (logical height 1125)
    property real s: height / 1125

    // background { path, blur (pre-blurred by sddm-sync), brightness = 0.7 }
    Image {
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.3
    }

    // Time: font_size 96, ExtraBold, position 0,160
    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -160 * root.s
        color: config.on_surface || "#f0dede"
        font.family: root.fontName
        font.weight: Font.ExtraBold
        font.pixelSize: 128 * root.s
        text: Qt.formatTime(new Date(), "HH:mm")
    }

    // Date: font_size 18, position 0,70
    Text {
        id: date
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -70 * root.s
        color: config.on_surface_variant || "#d7c1c2"
        font.family: root.fontName
        font.pixelSize: 24 * root.s
        text: Qt.formatDate(new Date(), "dddd, dd MMMM")
    }

    // Flirps OS branding
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * root.s
        color: config.primary || "#ffb2b7"
        font.family: root.fontName
        font.weight: Font.ExtraBold
        font.pixelSize: 22 * root.s
        text: "Flirps OS"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clock.text = Qt.formatTime(new Date(), "HH:mm")
            date.text = Qt.formatDate(new Date(), "dddd, dd MMMM")
        }
    }

    // input-field: 300x50, outline 2, rounding 12, position 0,-40
    Rectangle {
        id: field
        width: 300 * root.s
        height: 50 * root.s
        radius: 12 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 40 * root.s
        color: config.surface_container || "#271d1e"
        border.width: 2 * root.s
        border.color: root.failed ? (config.error || "#ffb4ab") : (config.primary || "#ffb2b7")

        TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 16 * root.s
            anchors.rightMargin: 16 * root.s
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            color: config.on_surface || "#f0dede"
            font.family: root.fontName
            font.pixelSize: 18 * root.s
            focus: true
            clip: true
            onTextChanged: if (text.length > 0) root.failed = false
            onAccepted: sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
            Keys.onEscapePressed: text = ""
        }

        Text {
            anchors.centerIn: parent
            visible: password.text.length === 0
            text: root.failed ? "Wrong password" : "Password"
            color: root.failed ? (config.error || "#ffb4ab") : (config.on_surface_variant || "#d7c1c2")
            opacity: root.failed ? 1.0 : 0.6
            font.family: root.fontName
            font.pixelSize: 16 * root.s
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            root.failed = true
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
