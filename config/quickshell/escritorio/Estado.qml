// Fuente de datos de los widgets: corre `escritorio estado` y expone el JSON.
// Se refresca cuando cambia el archivo de pendientes y, por las dudas (cambio de día), cada 2 min.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var datos: null
    property string error: ""

    // Se emite al abrir otra ventana: el panel se cierra para no quedar encima.
    signal abrio()
    // Pide abrir el tablero kanban de pendientes.
    signal pidioTablero()

    readonly property string home: Quickshell.env("HOME")
    // CLI de datos (bin/escritorio); los demás componentes lo usan también.
    readonly property string cli: home + "/.local/bin/escritorio"

    function refrescar() {
        if (!proceso.running)
            proceso.running = true;
    }

    function abrirTablero() {
        pidioTablero();
        abrio();
    }

    function agregarTarea(texto) {
        if (accion.running) return;
        accion.command = [cli, "tarea", "agregar", texto];
        accion.running = true;
    }

    // Cambia el estado de un pendiente; el texto evita marcar otro si la lista cambió.
    function marcarTarea(tarea, nuevoEstado) {
        if (accion.running) return;
        accion.command = [cli, "tarea", String(tarea.indice), nuevoEstado, "--texto", tarea.texto];
        accion.running = true;
    }

    Process {
        id: accion
        onExited: root.refrescar()
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("escritorio tarea:", text)
        }
    }

    Process {
        id: proceso
        command: [root.cli, "estado"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.datos = JSON.parse(text);
                    root.error = "";
                } catch (e) {
                    root.error = "No se pudo leer el estado";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("escritorio:", text)
        }
    }

    FileView {
        path: root.datos ? root.datos.archivo : ""
        watchChanges: true
        onFileChanged: root.refrescar()
    }

    Timer {
        interval: 2 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refrescar()
    }
}
