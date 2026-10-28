// Disposición común del escritorio y del panel (Super+D): pendientes y calendario lado a lado con
// la misma altura, y "Ahora suena" a lo ancho debajo (se oculta sin música).
import QtQuick

Column {
    id: tarjetas

    required property var estado
    required property var agenda
    property bool solido: false

    readonly property int alto: Math.max(pendientes.implicitHeight, calendario.implicitHeight)

    spacing: 16

    Row {
        spacing: 16
        PendientesContenido {
            id: pendientes
            estado: tarjetas.estado
            solido: tarjetas.solido
            height: tarjetas.alto
        }
        CalendarioContenido {
            id: calendario
            agenda: tarjetas.agenda
            solido: tarjetas.solido
            height: tarjetas.alto
        }
    }

    MusicaContenido {
        solido: tarjetas.solido
        ancho: pendientes.implicitWidth + calendario.implicitWidth + 16
    }
}
