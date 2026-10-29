// Tarjeta de pendientes y sugerencias de Faro: el checklist de Pendientes.md (ver cli/config.ts).
// Clic en el círculo = hecha, clic en el texto = alterna "en curso", clic en el encabezado = tablero kanban.
import QtQuick
import QtQuick.Layouts

Vidrio {
    id: tarjeta

    required property var estado
    readonly property var datos: estado.datos
    readonly property int maxTareas: 6
    readonly property var tareas: datos && datos.tareas ? datos.tareas : []
    readonly property var ideas: datos && datos.ideas ? datos.ideas : []

    implicitWidth: 346
    implicitHeight: contenido.implicitHeight + 36

    component Etiqueta: Text {
        color: tarjeta.tenue
        font { family: tarjeta.fuente; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.2 }
    }

    // Casilla redonda estilo Recordatorios de macOS. "En curso" se ve como un punto al centro.
    component Casilla: Rectangle {
        property bool marcada: false
        property bool enCurso: false
        signal pulsada()
        width: 18
        height: 18
        radius: 9
        color: marcada ? tarjeta.bien : "transparent"
        border.width: marcada ? 0 : 1.5
        border.color: enCurso ? tarjeta.texto : tarjeta.tenue
        Rectangle {
            anchors.centerIn: parent
            visible: parent.enCurso && !parent.marcada
            width: 8
            height: 8
            radius: 4
            color: tarjeta.texto
        }
        Text {
            anchors.centerIn: parent
            visible: parent.marcada
            text: "✓"
            color: Tema.fondo
            font { pixelSize: 11; weight: Font.Bold }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.pulsada()
        }
    }

    // Fila con resaltado al pasar el mouse y una acción al hacer clic.
    component Fila: Item {
        id: fila
        default property alias contenido: interior.data
        signal pulsada()
        Layout.fillWidth: true
        implicitHeight: interior.implicitHeight
        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            anchors.leftMargin: -7
            anchors.rightMargin: -7
            radius: 9
            color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.09 : 0)
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fila.pulsada()
        }
        RowLayout {
            id: interior
            anchors.fill: parent
            spacing: 12
        }
    }

    ColumnLayout {
        id: contenido
        // Anclado arriba: en la fila del panel la tarjeta puede ser más alta que su contenido.
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 12

        // Pendientes personales: círculo = hecha, texto = alterna "en curso"
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 9
            visible: !!tarjeta.datos

            // Encabezado → abre el tablero kanban
            Fila {
                onPulsada: tarjeta.estado.abrirTablero()
                Etiqueta { text: "MIS PENDIENTES" + (tarjeta.tareas.length ? " · " + tarjeta.tareas.length : "") }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Tablero ›"
                    color: tarjeta.muyTenue
                    font { family: tarjeta.fuente; pixelSize: 11 }
                }
            }

            Text {
                visible: tarjeta.tareas.length === 0
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Escribe «- [ ] algo» en Pendientes.md (o usa «escritorio tarea agregar») y aparece aquí."
                color: tarjeta.muyTenue
                font { family: tarjeta.fuente; pixelSize: 12; italic: true }
            }

            Repeater {
                model: tarjeta.tareas.slice(0, tarjeta.maxTareas)
                Fila {
                    id: filaTarea
                    required property var modelData
                    readonly property bool enCurso: modelData.estado === "en-curso"
                    onPulsada: tarjeta.estado.marcarTarea(modelData, enCurso ? "pendiente" : "en-curso")

                    Casilla {
                        enCurso: filaTarea.enCurso
                        onPulsada: tarjeta.estado.marcarTarea(filaTarea.modelData, "hecha")
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: filaTarea.modelData.texto
                        color: tarjeta.texto
                        font { family: tarjeta.fuente; pixelSize: 12; weight: filaTarea.enCurso ? Font.DemiBold : Font.Normal }
                    }
                    Text {
                        visible: filaTarea.enCurso
                        text: "en curso"
                        color: tarjeta.tenue
                        font { family: tarjeta.fuente; pixelSize: 10 }
                    }
                }
            }

            Text {
                visible: tarjeta.tareas.length > tarjeta.maxTareas
                text: "y " + (tarjeta.tareas.length - tarjeta.maxTareas) + " más en el tablero"
                color: tarjeta.muyTenue
                font { family: tarjeta.fuente; pixelSize: 11 }
            }

            ColumnLayout {
                visible: tarjeta.ideas.length > 0
                Layout.fillWidth: true
                spacing: 9

                Etiqueta { text: "FARO SUGIERE · " + tarjeta.ideas.length }

                Repeater {
                    model: tarjeta.ideas
                    Fila {
                        id: filaIdea
                        required property var modelData

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: filaIdea.modelData.etiqueta + " · " + filaIdea.modelData.proyecto
                                color: tarjeta.muyTenue
                                font { family: tarjeta.fuente; pixelSize: 10 }
                            }
                            Text {
                                id: ideaTexto
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                text: filaIdea.modelData.texto
                                color: tarjeta.texto
                                font { family: tarjeta.fuente; pixelSize: 12 }
                            }
                        }

                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: areaSi.containsMouse ? tarjeta.bien : Qt.rgba(1, 1, 1, 0.10)
                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: areaSi.containsMouse ? Tema.fondo : tarjeta.bien
                                font { family: tarjeta.fuente; pixelSize: 13; weight: Font.Bold }
                            }
                            MouseArea {
                                id: areaSi
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tarjeta.estado.decidirIdea(filaIdea.modelData, true)
                            }
                        }
                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: areaNo.containsMouse ? tarjeta.tenue : Qt.rgba(1, 1, 1, 0.10)
                            Text {
                                anchors.centerIn: parent
                                text: "✗"
                                color: areaNo.containsMouse ? Tema.fondo : tarjeta.tenue
                                font { family: tarjeta.fuente; pixelSize: 13; weight: Font.Bold }
                            }
                            MouseArea {
                                id: areaNo
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tarjeta.estado.decidirIdea(filaIdea.modelData, false)
                            }
                        }
                    }
                }
            }
        }
    }
}
