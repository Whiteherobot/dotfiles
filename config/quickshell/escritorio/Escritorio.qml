// Modo fondo: las tarjetas fijas arriba a la derecha, debajo de las ventanas.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: ventana

    required property var estado
    required property var agenda

    screen: Quickshell.screens[0]
    anchors.top: true
    anchors.right: true
    margins.top: 14
    margins.right: 14
    implicitWidth: columna.implicitWidth
    implicitHeight: columna.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "escritorio-escritorio"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Tarjetas {
        id: columna
        estado: ventana.estado
        agenda: ventana.agenda
    }
}
