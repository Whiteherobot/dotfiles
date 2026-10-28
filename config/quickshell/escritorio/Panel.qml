// Panel con Super+D: las tarjetas encima de todo, sobre el escritorio desenfocado.
// Se cierra con Esc, con un clic fuera de las tarjetas o con el mismo atajo.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel

    required property var estado
    required property var agenda
    property bool abierto: false

    function alternar() {
        abierto = !abierto;
        if (abierto) {
            estado.refrescar();
            agenda.refrescar(false);
        }
    }

    visible: abierto
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: Tema.velo
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "escritorio-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Connections {
        target: panel.estado
        function onAbrio() { panel.abierto = false; }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: panel.abierto = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: panel.abierto = false
    }

    Tarjetas {
        anchors.centerIn: parent
        estado: panel.estado
        agenda: panel.agenda
        solido: true
    }
}
