// Barras de audio para las tarjetas de música: un solo cava compartido (escritorio y panel),
// encendido solo mientras algún reproductor está sonando. `niveles` son 32 valores de 0 a 100.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: espectro

    readonly property int barras: 32
    readonly property bool sonando: Mpris.players.values.some(p => p.isPlaying && p.trackTitle)
    property var niveles: []

    Process {
        running: espectro.sonando
        command: ["cava", "-p", Qt.resolvedUrl("cava-musica.conf").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: linea => espectro.niveles = linea.split(";").filter(v => v !== "").map(Number)
        }
        onRunningChanged: if (!running) espectro.niveles = []
    }
}
