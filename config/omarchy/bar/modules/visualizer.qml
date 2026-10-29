import QtQuick
import Quickshell.Io

// Barras tipo ecualizador a partir de cava (~/.config/cava/waybar.conf). En silencio se oculta.
// Reemplaza a custom/visualizer de la Waybar; cava duerme solo en silencio (sleep_timer).
Item {
  id: root
  property var bar
  property string moduleName
  property var settings

  readonly property var glyphs: ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
  property string levels: ""

  visible: levels !== ""
  implicitWidth: visible ? label.implicitWidth + 8 : 0
  implicitHeight: bar ? bar.barSize : 26

  Text {
    id: label
    anchors.centerIn: parent
    text: root.levels
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 12
  }

  MouseArea {
    anchors.fill: parent
    onClicked: if (bar) bar.run("omarchy-launch-audio")
  }

  Process {
    id: cava
    command: ["sh", "-c", "exec cava -p \"$HOME/.config/cava/waybar.conf\""]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        let out = "", total = 0
        for (const v of String(line).split(";")) {
          const n = parseInt(v)
          if (n >= 0 && n <= 7) { out += root.glyphs[n]; total += n }
        }
        root.levels = total === 0 ? "" : out
      }
    }
    // Si cava sale (p. ej. arrancó antes que PipeWire), relanzarlo.
    onExited: restart.start()
  }

  Timer {
    id: restart
    interval: 3000
    onTriggered: cava.running = true
  }
}
