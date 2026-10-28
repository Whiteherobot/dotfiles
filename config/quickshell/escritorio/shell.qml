// Widgets del escritorio (Quickshell): pendientes, calendario y música. Se instala como
// ~/.config/quickshell/escritorio y se lanza con `quickshell -c escritorio`; el panel: `quickshell -c escritorio ipc call escritorio alternar`.
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Estado {
        id: estado
    }

    Agenda {
        id: agenda
        estado: estado
    }

    Escritorio {
        estado: estado
        agenda: agenda
    }

    Panel {
        id: panel
        estado: estado
        agenda: agenda
    }

    Calendario {
        id: vistaCalendario
        agenda: agenda
    }

    Tablero {
        id: kanban
        estado: estado
    }

    Connections {
        target: estado
        function onPidioTablero() { kanban.alternar(); }
    }

    Connections {
        target: agenda
        function onPidioCalendario(fecha, anio) { vistaCalendario.abrirEn(fecha, anio); }
    }

    IpcHandler {
        target: "escritorio"
        function alternar(): void { panel.alternar(); }
        function tablero(): void { kanban.alternar(); }
        function calendario(): void {
            if (vistaCalendario.abierto) vistaCalendario.cerrar();
            else vistaCalendario.abrirEn(agenda.dia);
        }
        function anio(): void { vistaCalendario.abrirEn(agenda.dia, true); }
        // Abre el tablero en la ficha de la tarea `indice` (la del archivo Pendientes.md).
        function detalle(indice: int): void {
            const tarea = kanban.tareas.find(t => t.indice === indice);
            if (!tarea) return;
            if (!kanban.abierto) kanban.alternar();
            kanban.verDetalle(tarea);
        }
    }
}
