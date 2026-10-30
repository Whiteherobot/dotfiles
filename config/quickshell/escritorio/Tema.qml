// Colores del tema actual de Omarchy (colors.toml del tema aplicado). Si cambias de tema,
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
    // Colores de acento para calendarios y avisos.
    property color amarillo: "#d7ab5b"
    property color azul: "#5b9dd7"
    property color rojo: "#c07878"
    property color verde: "#8fbf7f"

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

    // Omarchy 4 renderiza el tema en ~/.local/state/omarchy/current/theme y ya no genera
    // quickshell.json: todo sale de colors.toml.
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const leer = clave => {
                const m = new RegExp("^" + clave + "\\s*=\\s*\"(#[0-9a-fA-F]{6})\"", "m").exec(text());
                return m ? m[1] : null;
            };
            tema.fondo = leer("background") || tema.fondo;
            tema.primario = leer("accent") || tema.primario;
            tema.texto = leer("foreground") || tema.texto;
            tema.brilloArriba = leer("bright_magenta") || tema.brilloArriba;
            tema.brilloMedio = leer("bright_green") || tema.brilloMedio;
            tema.amarillo = leer("yellow") || tema.amarillo;
            tema.azul = leer("blue") || tema.azul;
            tema.rojo = leer("red") || tema.rojo;
            tema.verde = leer("green") || tema.verde;
        }
    }
}
