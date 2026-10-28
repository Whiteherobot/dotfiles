// Fondo de vidrio esmerilado estilo widget de macOS. El blur real lo pone Hyprland
// (layer_rule con blur + ignore_alpha sobre el namespace "escritorio-*").
import QtQuick

Rectangle {
    // Paleta compartida por las tarjetas.
    readonly property color texto: Tema.texto
    readonly property color tenue: Tema.tenue
    readonly property color muyTenue: Tema.muyTenue
    readonly property color bien: Tema.primario
    readonly property string fuente: "Inter Variable"

    radius: 22
    border.width: 1
    border.color: solido ? Tema.conAlfa(Tema.primario, 0.35) : Qt.rgba(1, 1, 1, 0.24)

    // En el panel (Super+D) y el tablero va casi opaco con los colores del tema: sobre el escritorio
    // oscurecido, el vidrio translúcido no se distinguía.
    property bool solido: false

    // Brillo sutil arriba, como la luz que pega en el vidrio.
    gradient: Gradient {
        GradientStop { position: 0.0; color: solido ? Tema.solidoArriba : Qt.rgba(1, 1, 1, 0.20) }
        GradientStop { position: 1.0; color: solido ? Tema.solidoAbajo : Qt.rgba(1, 1, 1, 0.10) }
    }
}
