// Tablero kanban de los pendientes: Por hacer · En curso · Hechas, con el vidrio del panel.
// Se abre con clic en "MIS PENDIENTES" (o `ipc call escritorio tablero`); se cierra con Esc o clic fuera.
// Todo pasa por la CLI (`tarea …`), así el archivo de Obsidian sigue siendo la fuente de verdad.
// Clic en una tarea → ficha con el avance de su nota vinculada (`tarea detalle`).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: tablero

    required property var estado
    property bool abierto: false

    readonly property var tareas: estado.datos && estado.datos.todasLasTareas ? estado.datos.todasLasTareas : []
    readonly property var columnas: [
        { id: "pendiente", titulo: "POR HACER" },
        { id: "en-curso", titulo: "EN CURSO" },
        { id: "hecha", titulo: "HECHAS" }
    ]
    readonly property var orden: ["pendiente", "en-curso", "hecha"]

    // Ficha de detalle: la tarea abierta y lo que devolvió `tarea detalle` (null = sin nota).
    property var tareaAbierta: null
    property var detalle: null
    property bool cargando: false

    function alternar() {
        abierto = !abierto;
        tareaAbierta = null;
        if (abierto) {
            estado.refrescar();
            nueva.forceActiveFocus();
        }
    }

    // Esc o clic fuera: primero cierra la ficha, después el tablero.
    function cerrar() {
        if (tareaAbierta) tareaAbierta = null;
        else abierto = false;
    }

    function verDetalle(tarea) {
        tareaAbierta = tarea;
        detalle = null;
        cargando = true;
        consulta.command = [estado.cli, "tarea", "detalle", String(tarea.indice)];
        consulta.running = true;
    }

    function hace(fecha) {
        const [a, m, d] = fecha.split("-").map(Number);
        const dias = Math.round((new Date().setHours(0, 0, 0, 0) - new Date(a, m - 1, d)) / 86400000);
        return dias <= 0 ? "hoy" : dias === 1 ? "ayer" : "hace " + dias + " días";
    }

    Process {
        id: consulta
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    tablero.detalle = JSON.parse(text);
                } catch (e) {
                    tablero.detalle = null;
                }
                tablero.cargando = false;
            }
        }
    }

    function mover(tarea, paso) {
        estado.marcarTarea(tarea, orden[orden.indexOf(tarea.estado) + paso]);
    }

    visible: abierto
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: Tema.velo
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "escritorio-tablero"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
        anchors.fill: parent
        onClicked: tablero.cerrar()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: tablero.cerrar()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // Cabecera: título + campo para agregar
        Vidrio {
            id: cabecera
            solido: true
            Layout.fillWidth: true
            implicitHeight: 64

            // Absorbe los clics para que no cierren el tablero.
            MouseArea { anchors.fill: parent }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 14
                spacing: 16

                Text {
                    text: "Pendientes"
                    color: cabecera.texto
                    font { family: cabecera.fuente; pixelSize: 18; weight: Font.DemiBold }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 12
                    color: Tema.conAlfa(Tema.texto, nueva.activeFocus ? 0.16 : 0.10)
                    border.width: 1
                    border.color: Tema.conAlfa(Tema.texto, nueva.activeFocus ? 0.40 : 0.18)

                    TextInput {
                        id: nueva
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: cabecera.texto
                        selectionColor: Tema.conAlfa(Tema.texto, 0.3)
                        font { family: cabecera.fuente; pixelSize: 13 }
                        clip: true
                        Keys.onEscapePressed: tablero.cerrar()
                        onAccepted: {
                            if (!text.trim()) return;
                            tablero.estado.agregarTarea(text.trim());
                            text = "";
                        }

                        Text {
                            visible: !nueva.text && !nueva.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Nueva tarea… (Enter para agregar)"
                            color: cabecera.muyTenue
                            font: nueva.font
                        }
                        Text {
                            visible: !nueva.text && nueva.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Escribe y presiona Enter"
                            color: cabecera.muyTenue
                            font: nueva.font
                        }
                    }
                }

                Text {
                    text: "Esc para cerrar"
                    color: cabecera.muyTenue
                    font { family: cabecera.fuente; pixelSize: 11 }
                }
            }
        }

        // Columnas
        Row {
            spacing: 16

            Repeater {
                model: tablero.columnas

                Vidrio {
                    id: columna
                    required property var modelData
                    readonly property var lista: tablero.tareas.filter(t => t.estado === modelData.id)

                    solido: true
                    width: 320
                    height: Math.min(tablero.height * 0.7, 560)

                    MouseArea { anchors.fill: parent }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: columna.modelData.titulo
                                color: columna.tenue
                                font { family: columna.fuente; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.2 }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: columna.lista.length
                                color: columna.muyTenue
                                font { family: columna.fuente; pixelSize: 11; features: { "tnum": 1 } }
                            }
                        }

                        Text {
                            visible: columna.lista.length === 0
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: columna.modelData.id === "pendiente" ? "Nada por hacer." : columna.modelData.id === "en-curso" ? "Nada en curso." : "Aún nada terminado."
                            color: columna.muyTenue
                            font { family: columna.fuente; pixelSize: 12; italic: true }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: columna.lista

                            delegate: Rectangle {
                                id: tarjeta
                                required property var modelData
                                readonly property int pos: tablero.orden.indexOf(modelData.estado)

                                width: ListView.view.width
                                implicitHeight: interior.implicitHeight + 24
                                radius: 12
                                color: Tema.conAlfa(Tema.texto, hover.hovered ? 0.16 : 0.10)
                                border.width: 1
                                border.color: Tema.conAlfa(Tema.texto, 0.14)

                                HoverHandler { id: hover }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tablero.verDetalle(tarjeta.modelData)
                                }

                                RowLayout {
                                    id: interior
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Boton {
                                        visible: tarjeta.pos > 0
                                        text: "‹"
                                        onPulsado: tablero.mover(tarjeta.modelData, -1)
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: tarjeta.modelData.texto
                                            color: columna.texto
                                            opacity: tarjeta.modelData.estado === "hecha" ? 0.6 : 1
                                            font {
                                                family: columna.fuente
                                                pixelSize: 13
                                                strikeout: tarjeta.modelData.estado === "hecha"
                                            }
                                        }
                                        Text {
                                            visible: !!tarjeta.modelData.nota
                                            text: "Ver avance"
                                            color: columna.muyTenue
                                            font { family: columna.fuente; pixelSize: 10 }
                                        }
                                    }
                                    Boton {
                                        visible: tarjeta.pos < 2
                                        text: tarjeta.pos === 1 ? "✓" : "›"
                                        onPulsado: tablero.mover(tarjeta.modelData, 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Ficha de avance de la tarea: encima del tablero, con el mismo vidrio.
    Item {
        anchors.fill: parent
        visible: !!tablero.tareaAbierta

        Rectangle {
            anchors.fill: parent
            color: Tema.velo
        }
        MouseArea {
            anchors.fill: parent
            onClicked: tablero.cerrar()
        }

        Vidrio {
            id: ficha
            solido: true
            anchors.centerIn: parent
            width: 640
            height: Math.min(parent.height * 0.8, cuerpo.implicitHeight + 48)

            MouseArea { anchors.fill: parent }

            Flickable {
                anchors.fill: parent
                anchors.margins: 24
                contentHeight: cuerpo.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: cuerpo
                    width: parent.width
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: tablero.tareaAbierta ? tablero.tareaAbierta.texto : ""
                            color: ficha.texto
                            font { family: ficha.fuente; pixelSize: 18; weight: Font.DemiBold }
                        }
                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: "Esc para volver"
                            color: ficha.muyTenue
                            font { family: ficha.fuente; pixelSize: 11 }
                        }
                    }

                    Text {
                        visible: !!tablero.detalle
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: tablero.detalle ? tablero.detalle.nota + " · actualizada " + tablero.hace(tablero.detalle.modificada) : ""
                        color: ficha.muyTenue
                        font { family: ficha.fuente; pixelSize: 11 }
                    }

                    Text {
                        visible: tablero.cargando || !tablero.detalle
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: tablero.cargando ? "Leyendo la nota…"
                            : tablero.tareaAbierta && tablero.tareaAbierta.nota ? "No encontré la nota «" + tablero.tareaAbierta.nota + "» en la carpeta de notas."
                            : "Esta tarea no tiene nota vinculada. Agrégale [[Nombre de la nota]] al final en Pendientes.md."
                        color: ficha.tenue
                        font { family: ficha.fuente; pixelSize: 12; italic: true }
                    }

                    // Aviso de estado (primer callout de la nota)
                    Rectangle {
                        visible: !!tablero.detalle && !!tablero.detalle.aviso
                        Layout.fillWidth: true
                        implicitHeight: textoAviso.implicitHeight + 24
                        radius: 12
                        color: Tema.conAlfa(Tema.primario, 0.16)
                        border.width: 1
                        border.color: Tema.conAlfa(Tema.primario, 0.40)
                        Text {
                            id: textoAviso
                            anchors.fill: parent
                            anchors.margins: 12
                            wrapMode: Text.Wrap
                            textFormat: Text.MarkdownText
                            text: tablero.detalle && tablero.detalle.aviso ? tablero.detalle.aviso.texto : ""
                            color: ficha.texto
                            font { family: ficha.fuente; pixelSize: 12 }
                        }
                    }

                    // Checklist de la nota: barra + lo siguiente por hacer
                    ColumnLayout {
                        readonly property var lista: tablero.detalle ? tablero.detalle.checklist : null
                        visible: !!lista
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Etiqueta { text: "CHECKLIST" }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: parent.parent.lista ? parent.parent.lista.hechos + "/" + parent.parent.lista.total : ""
                                color: ficha.muyTenue
                                font { family: ficha.fuente; pixelSize: 11; features: { "tnum": 1 } }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Tema.conAlfa(Tema.texto, 0.14)
                            Rectangle {
                                readonly property var lista: parent.parent.lista
                                height: parent.height
                                radius: 3
                                color: Tema.primario
                                width: lista && lista.total ? Math.max(lista.hechos ? 6 : 0, parent.width * lista.hechos / lista.total) : 0
                            }
                        }
                        Repeater {
                            model: parent.lista ? parent.lista.siguientes : []
                            Text {
                                required property string modelData
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                textFormat: Text.MarkdownText
                                text: "○  " + modelData
                                color: ficha.tenue
                                font { family: ficha.fuente; pixelSize: 12 }
                            }
                        }
                    }

                    // Secciones de avance de la nota (Estado, Pendiente, Historial…)
                    Repeater {
                        model: tablero.detalle ? tablero.detalle.secciones : []
                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 6
                            Etiqueta { text: modelData.titulo.toUpperCase() }
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                textFormat: Text.MarkdownText
                                text: modelData.texto
                                color: ficha.texto
                                font { family: ficha.fuente; pixelSize: 12 }
                            }
                        }
                    }

                    Rectangle {
                        visible: !!tablero.detalle
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: abrir.implicitWidth + 28
                        implicitHeight: 32
                        radius: 16
                        color: Tema.conAlfa(Tema.texto, areaAbrir.containsMouse ? 0.22 : 0.10)
                        Text {
                            id: abrir
                            anchors.centerIn: parent
                            text: "Abrir en Obsidian ›"
                            color: ficha.texto
                            font { family: ficha.fuente; pixelSize: 12; weight: Font.DemiBold }
                        }
                        MouseArea {
                            id: areaAbrir
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["xdg-open", "obsidian://open?path=" + encodeURIComponent(tablero.detalle.ruta)]);
                                tablero.abierto = false;
                            }
                        }
                    }
                }
            }
        }
    }

    component Etiqueta: Text {
        color: Tema.tenue
        font { family: "Inter Variable"; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.2 }
    }

    // Botón redondo para mover la tarea a la columna vecina.
    component Boton: Rectangle {
        property alias text: etiqueta.text
        signal pulsado()
        Layout.alignment: Qt.AlignVCenter
        width: 26
        height: 26
        radius: 13
        color: Tema.conAlfa(Tema.texto, area.containsMouse ? 0.24 : 0.10)
        Text {
            id: etiqueta
            anchors.centerIn: parent
            color: Tema.texto
            font { family: "Inter Variable"; pixelSize: 15; weight: Font.DemiBold }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.pulsado()
        }
    }
}
