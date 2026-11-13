import QtQuick
import Quickshell
import "CalculatorEngine.js" as Calc

// Floating calculator (SUPER+=). Type or click; Enter = result, Esc closes, Ctrl+C copies.
ToolWindow {
    id: root
    title: "Calculator"
    icon: 0xF00EC
    startX: 1500; startY: 90

    property string expr: ""
    property string last: ""
    readonly property string preview: {
        if (!expr) return "";
        try { const v = Calc.evaluate(Calc.trimTrailing(expr), false); return isFinite(v) ? Calc.format(v) : ""; } catch (e) { return ""; }
    }
    onOpened: keys.forceActiveFocus()

    function press(k) {
        if (k === "C") { expr = ""; last = ""; }
        else if (k === "⌫") expr = expr.slice(0, -1);
        else if (k === "=") { if (preview) { last = expr + " ="; expr = preview.replace("−", "-"); } }
        else expr += k;
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) root.close();
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.text === "=") root.press("=");
            else if (e.key === Qt.Key_Backspace) root.press("⌫");
            else if (e.key === Qt.Key_Delete) root.press("C");
            else if (e.key === Qt.Key_C && (e.modifiers & Qt.ControlModifier)) Quickshell.execDetached(["wl-copy", "--", (root.preview || root.expr).replace("−", "-")]);
            else if (e.text === "*") root.press("×");
            else if (e.text === "/") root.press("÷");
            else if (/^[0-9.+\-()^%a-z]$/.test(e.text)) root.press(e.text);
            else return;
            e.accepted = true;
        }
    }

    Column {
        spacing: 10
        Rectangle {
            width: 4 * 62 + 3 * 8; height: 92; radius: 18
            color: Theme.surfaceLow
            Column {
                anchors.right: parent.right; anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32
                SText { width: parent.width; horizontalAlignment: Text.AlignRight; text: root.last || " "; dim: true; font.pixelSize: 12 }
                SText { width: parent.width; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft; text: root.expr || "0"; font.pixelSize: 26; font.weight: Font.Bold }
                SText { width: parent.width; horizontalAlignment: Text.AlignRight; text: root.preview && root.preview !== root.expr ? "= " + root.preview : " "; color: Theme.primary; font.pixelSize: 13 }
            }
        }
        Grid {
            columns: 4; spacing: 8
            Repeater {
                model: ["C", "(", ")", "÷", "7", "8", "9", "×", "4", "5", "6", "-", "1", "2", "3", "+", "0", ".", "⌫", "="]
                Rectangle {
                    required property string modelData
                    readonly property bool op: "÷×-+".includes(modelData)
                    readonly property bool eq: modelData === "="
                    width: 62; height: 52
                    radius: km.pressed ? 14 : 26
                    Behavior on radius { NumberAnimation { duration: 120 } }
                    color: eq ? Theme.primary : op ? Theme.secondaryContainer : modelData === "C" ? Theme.primaryContainer : (km.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh)
                    SText {
                        anchors.centerIn: parent; text: parent.modelData; font.pixelSize: 18; font.weight: Font.Bold
                        color: parent.eq ? Theme.fgPrimary : parent.op ? Theme.fgSecondaryContainer : parent.modelData === "C" ? Theme.fgPrimaryContainer : Theme.text
                    }
                    MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.press(parent.modelData); keys.forceActiveFocus(); } }
                }
            }
        }
    }
}
