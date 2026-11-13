pragma Singleton
import QtQuick
import Quickshell
import "EmojiData.js" as Data

// Only instantiated the first time ":" is typed in the launcher.
Singleton {
    function load() { return Data.emojis; }
}
