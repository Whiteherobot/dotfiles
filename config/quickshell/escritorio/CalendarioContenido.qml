// Tarjeta de calendario: el mes con hoy marcado y un punto en los días con eventos, y los próximos
// eventos de Google Calendar. Clic en el encabezado o en un día → vista grande (Calendario.qml).
import QtQuick
import QtQuick.Layouts

Vidrio {
    id: tarjeta

    required property var agenda
    readonly property var datos: agenda.datos
    readonly property int maxProximos: 3
    readonly property string hoy: agenda.dia
    readonly property string inicio: agenda.inicioCuadricula(hoy)
    // Filas que de verdad ocupa el mes (4 a 6), para no dejar una semana vacía al final.
    readonly property int filas: {
        const d = agenda.fecha(hoy);
        const dias = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        const desfase = (agenda.fecha(hoy.slice(0, 8) + "01").getDay() + 6) % 7;
        return Math.ceil((desfase + dias) / 7);
    }

    // Próximos eventos desde ahora: los de hoy que no terminaron y los de días siguientes.
    readonly property var proximos: {
        if (!datos || !datos.dias) return [];
        const ahora = new Date();
        const hora = String(ahora.getHours()).padStart(2, "0") + ":" + String(ahora.getMinutes()).padStart(2, "0");
        const lista = [];
        for (let i = 0; i < 15 && lista.length < maxProximos; i++) {
            const f = agenda.sumarDias(hoy, i);
            for (const e of (datos.dias[f] || [])) {
                if (i === 0 && !e.todoElDia && (e.fin || e.inicio) < hora) continue;
                lista.push(Object.assign({ fecha: f }, e));
                if (lista.length >= maxProximos) break;
            }
        }
        return lista;
    }

    implicitWidth: 346
    implicitHeight: contenido.implicitHeight + 36

    component Etiqueta: Text {
        color: tarjeta.tenue
        font { family: tarjeta.fuente; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.2 }
    }

    ColumnLayout {
        id: contenido
        // Anclado arriba: en la fila del panel la tarjeta puede ser más alta que su contenido.
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 12

        // Encabezado → vista grande
        Item {
            Layout.fillWidth: true
            implicitHeight: cabecera.implicitHeight
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                anchors.leftMargin: -7
                anchors.rightMargin: -7
                radius: 9
                color: Qt.rgba(1, 1, 1, areaCabecera.containsMouse ? 0.09 : 0)
            }
            MouseArea {
                id: areaCabecera
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tarjeta.agenda.abrir(tarjeta.hoy)
            }
            RowLayout {
                id: cabecera
                anchors.fill: parent
                Etiqueta { text: "CALENDARIO" }
                Item { Layout.fillWidth: true }
                // El mes → los 12 meses del año.
                Text {
                    text: tarjeta.agenda.nombreMes(tarjeta.hoy).charAt(0).toUpperCase() + tarjeta.agenda.nombreMes(tarjeta.hoy).slice(1) + " ›"
                    color: areaMes.containsMouse ? tarjeta.texto : tarjeta.muyTenue
                    font { family: tarjeta.fuente; pixelSize: 11 }
                    MouseArea {
                        id: areaMes
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tarjeta.agenda.abrir(tarjeta.hoy, true)
                    }
                }
            }
        }

        // Mes en miniatura
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 0

            Repeater {
                model: ["L", "M", "M", "J", "V", "S", "D"]
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: tarjeta.muyTenue
                    font { family: tarjeta.fuente; pixelSize: 10; weight: Font.DemiBold }
                }
            }

            Repeater {
                model: tarjeta.filas * 7
                Item {
                    id: celda
                    required property int index
                    readonly property string dia: tarjeta.agenda.sumarDias(tarjeta.inicio, index)
                    readonly property bool esHoy: dia === tarjeta.hoy
                    readonly property bool delMes: dia.slice(0, 7) === tarjeta.hoy.slice(0, 7)
                    readonly property var eventos: tarjeta.datos && tarjeta.datos.dias ? (tarjeta.datos.dias[dia] || []) : []

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 30

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 2
                        width: 24
                        height: 24
                        radius: 12
                        color: celda.esHoy ? Tema.primario : Qt.rgba(1, 1, 1, areaDia.containsMouse ? 0.12 : 0)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 2
                        height: 24
                        verticalAlignment: Text.AlignVCenter
                        text: tarjeta.agenda.fecha(celda.dia).getDate()
                        color: celda.esHoy ? Tema.fondo : tarjeta.texto
                        opacity: celda.delMes ? 1 : 0.35
                        font { family: tarjeta.fuente; pixelSize: 11; weight: celda.esHoy ? Font.Bold : Font.Normal; features: { "tnum": 1 } }
                    }
                    // Punto de eventos (color del primer calendario con algo ese día)
                    Rectangle {
                        visible: celda.eventos.length > 0 && !celda.esHoy
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 4
                        radius: 2
                        color: celda.eventos.length ? tarjeta.agenda.color(celda.eventos[0].calendario) : "transparent"
                        opacity: celda.delMes ? 1 : 0.4
                    }
                    MouseArea {
                        id: areaDia
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tarjeta.agenda.abrir(celda.dia)
                    }
                }
            }
        }

        // Próximos eventos
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Etiqueta { text: "PRÓXIMOS" }

            Text {
                visible: !tarjeta.datos || !tarjeta.datos.configurado
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: !tarjeta.datos ? "Leyendo el calendario…" : "Pega la dirección secreta iCal de tu Google Calendar en ~/.config/escritorio/calendarios.txt"
                color: tarjeta.muyTenue
                font { family: tarjeta.fuente; pixelSize: 12; italic: true }
            }

            Text {
                visible: !!tarjeta.datos && tarjeta.datos.configurado && tarjeta.proximos.length === 0
                text: "Nada en las próximas dos semanas."
                color: tarjeta.muyTenue
                font { family: tarjeta.fuente; pixelSize: 12; italic: true }
            }

            Repeater {
                model: tarjeta.proximos
                Item {
                    id: filaEvento
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: filaInterior.implicitHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -5
                        anchors.leftMargin: -7
                        anchors.rightMargin: -7
                        radius: 9
                        color: Qt.rgba(1, 1, 1, areaEvento.containsMouse ? 0.09 : 0)
                    }
                    MouseArea {
                        id: areaEvento
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tarjeta.agenda.abrir(filaEvento.modelData.fecha)
                    }
                    RowLayout {
                        id: filaInterior
                        anchors.fill: parent
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.fillHeight: true
                            radius: 1.5
                            color: tarjeta.agenda.color(filaEvento.modelData.calendario)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: filaEvento.modelData.titulo || "(sin título)"
                                color: tarjeta.texto
                                font { family: tarjeta.fuente; pixelSize: 12; weight: Font.DemiBold }
                            }
                            Text {
                                text: tarjeta.agenda.diaRelativo(filaEvento.modelData.fecha) + " · " + (filaEvento.modelData.todoElDia ? "todo el día" : filaEvento.modelData.inicio + (filaEvento.modelData.fin ? "–" + filaEvento.modelData.fin : ""))
                                color: tarjeta.muyTenue
                                font { family: tarjeta.fuente; pixelSize: 10; features: { "tnum": 1 } }
                            }
                        }
                    }
                }
            }

            Text {
                visible: !!tarjeta.datos && (tarjeta.datos.sinConexion || tarjeta.datos.errores.length > 0)
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: !tarjeta.datos ? "" : tarjeta.datos.errores.length ? "No pude leer: " + tarjeta.datos.errores.join(" · ") : "Sin conexión: mostrando la última copia"
                color: "#ffd27a"
                font { family: tarjeta.fuente; pixelSize: 10 }
            }
        }
    }
}
