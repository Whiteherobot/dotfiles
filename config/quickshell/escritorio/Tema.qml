// Colores del tema actual de Omarchy (current/theme/quickshell.json). Si cambias de tema,
// los widgets lo siguen solos. Los valores por defecto son los del tema con que se armó.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: tema

    property color fondo: "#040808"
    property color primario: "#648887"
    property color texto: "#BDD0C5"
    // Para el degradado de las barras de música (colors.toml del tema): arriba → medio.
    property color brilloArriba: "#94ced7"
    property color brilloMedio: "#bae5cd"

    readonly property color tenue: conAlfa(texto, 0.66)
    readonly property color muyTenue: conAlfa(texto, 0.42)
    // Velo detrás del panel y el tablero.
    readonly property color velo: conAlfa(fondo, 0.6)
    // Tarjetas opacas (panel y tablero): fondo del tema con un toque del primario arriba.
    readonly property color solidoArriba: conAlfa(Qt.tint(fondo, conAlfa(primario, 0.22)), 1)
    readonly property color solidoAbajo: conAlfa(Qt.tint(fondo, conAlfa(primario, 0.08)), 1)

    function conAlfa(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/quickshell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                if (c.background) tema.fondo = c.background;
                if (c.primary) tema.primario = c.primary;
                if (c.backgroundText) tema.texto = c.backgroundText;
            } catch (e) {
                console.warn("escritorio: tema ilegible", e);
            }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/colors.toml"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const leer = clave => {
                const m = new RegExp("^" + clave + "\\s*=\\s*\"(#[0-9a-fA-F]{6})\"", "m").exec(text());
                return m ? m[1] : null;
            };
            tema.brilloArriba = leer("bright_magenta") || tema.brilloArriba;
            tema.brilloMedio = leer("bright_green") || tema.brilloMedio;
        }
    }
}
