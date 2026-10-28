// Vista grande del calendario, con el vidrio del tablero: el mes con los eventos de cada día y,
// a la derecha, el detalle del día elegido. Se abre con clic en la tarjeta (o `ipc call escritorio calendario`);
// se cierra con Esc o clic fuera. Clic en el título (o en el mes de la tarjeta) muestra los 12 meses.
// ←/→ cambian de día, ↑/↓ de semana, RePág/AvPág de mes, Inicio vuelve a hoy.
// Es de solo lectura (iCal): "Nuevo evento" abre el formulario de Google con el día puesto.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: vista

    required property var agenda
    property bool abierto: false
    property string elegido: agenda.dia
    // Mes que se está mostrando (cualquier día de ese mes).
    property string mesVisto: agenda.dia
    // true = los 12 meses del año de `mesVisto`.
    property bool vistaAnio: false

    readonly property string inicio: agenda.inicioCuadricula(mesVisto)
    readonly property var datos: agenda.mes && agenda.mes.desde === inicio ? agenda.mes : null
    readonly property var eventosDia: datos && datos.dias[elegido] ? datos.dias[elegido] : []

    function abrirEn(fecha, anio) {
        elegido = fecha;
        mesVisto = fecha;
        vistaAnio = !!anio;
        abierto = true;
        agenda.cargarMes(fecha);
        foco.forceActiveFocus();
    }

    // Esc o clic fuera: desde el año vuelve al mes; desde el mes cierra.
    function cerrar() {
        if (vistaAnio) vistaAnio = false;
        else abierto = false;
    }

    function irAMes(anio, mes) {
        const d = agenda.fecha(elegido);
        const dias = new Date(anio, mes + 1, 0).getDate();
        elegir(agenda.iso(new Date(anio, mes, Math.min(d.getDate(), dias))));
        vistaAnio = false;
    }

    function elegir(fecha) {
        elegido = fecha;
        if (fecha.slice(0, 7) !== mesVisto.slice(0, 7)) {
            mesVisto = fecha;
            agenda.cargarMes(fecha);
        }
    }

    function cambiarMes(n) {
        const d = agenda.fecha(mesVisto.slice(0, 8) + "01");
        d.setMonth(d.getMonth() + (vistaAnio ? 12 * n : n));
        if (vistaAnio) mesVisto = agenda.iso(d);
        else elegir(agenda.iso(d));
    }

    function tituloDia(fecha) {
        const d = agenda.fecha(fecha);
        const n = agenda.diasSemana[d.getDay()];
        return n.charAt(0).toUpperCase() + n.slice(1) + " " + d.getDate() + " de " + agenda.meses[d.getMonth()];
    }

    visible: abierto
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: Tema.velo
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "escritorio-calendario"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
        anchors.fill: parent
        onClicked: vista.cerrar()
    }

    Item {
        id: foco
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: vista.cerrar()
        Keys.onLeftPressed: vista.elegir(vista.agenda.sumarDias(vista.elegido, -1))
        Keys.onRightPressed: vista.elegir(vista.agenda.sumarDias(vista.elegido, 1))
        Keys.onUpPressed: vista.elegir(vista.agenda.sumarDias(vista.elegido, -7))
        Keys.onDownPressed: vista.elegir(vista.agenda.sumarDias(vista.elegido, 7))
        Keys.onPressed: e => {
            if (e.key === Qt.Key_PageUp) vista.cambiarMes(-1);
            else if (e.key === Qt.Key_PageDown) vista.cambiarMes(1);
            else if (e.key === Qt.Key_Home) vista.elegir(vista.agenda.dia);
            else return;
            e.accepted = true;
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // Cabecera: mes, navegación y atajos
        Vidrio {
            id: cabecera
            solido: true
            Layout.fillWidth: true
            implicitHeight: 64

            MouseArea { anchors.fill: parent }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 14
                spacing: 12

                // Título: clic alterna entre el mes y los 12 meses del año.
                Rectangle {
                    implicitWidth: titulo.implicitWidth + 20
                    implicitHeight: 36
                    radius: 12
                    color: Tema.conAlfa(Tema.texto, areaTitulo.containsMouse ? 0.12 : 0)
                    Text {
                        id: titulo
                        anchors.centerIn: parent
                        text: {
                            const d = vista.agenda.fecha(vista.mesVisto);
                            if (vista.vistaAnio) return d.getFullYear() + "  ▴";
                            const m = vista.agenda.meses[d.getMonth()];
                            return m.charAt(0).toUpperCase() + m.slice(1) + " " + d.getFullYear() + "  ▾";
                        }
                        color: cabecera.texto
                        font { family: cabecera.fuente; pixelSize: 18; weight: Font.DemiBold }
                    }
                    MouseArea {
                        id: areaTitulo
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: vista.vistaAnio = !vista.vistaAnio
                    }
                }
                Text {
                    visible: !vista.datos
                    text: "cargando…"
                    color: cabecera.muyTenue
                    font { family: cabecera.fuente; pixelSize: 11; italic: true }
                }
                Item { Layout.fillWidth: true }
                Boton { text: "‹"; onPulsado: vista.cambiarMes(-1) }
                Pildora { text: "Hoy"; onPulsado: { vista.vistaAnio = false; vista.elegir(vista.agenda.dia); } }
                Boton { text: "›"; onPulsado: vista.cambiarMes(1) }
                Text {
                    Layout.leftMargin: 8
                    text: "Esc para cerrar"
                    color: cabecera.muyTenue
                    font { family: cabecera.fuente; pixelSize: 11 }
                }
            }
        }

        Row {
            spacing: 16

            // Mes
            Vidrio {
                id: mes
                solido: true
                width: 7 * 104 + 36
                height: Math.min(vista.height * 0.72, 6 * 92 + 70)

                MouseArea { anchors.fill: parent }

                // Los 12 meses del año: clic en uno → ese mes.
                GridLayout {
                    visible: vista.vistaAnio
                    anchors.fill: parent
                    anchors.margins: 18
                    columns: 4
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: 12
                        Rectangle {
                            id: mesAnio
                            required property int index
                            readonly property int anio: vista.agenda.fecha(vista.mesVisto).getFullYear()
                            readonly property string primero: anio + "-" + String(index + 1).padStart(2, "0") + "-01"
                            readonly property string inicio: vista.agenda.inicioCuadricula(primero)
                            readonly property bool esActual: vista.agenda.dia.slice(0, 7) === primero.slice(0, 7)
                            readonly property bool esElegido: vista.elegido.slice(0, 7) === primero.slice(0, 7)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 1
                            radius: 12
                            color: Tema.conAlfa(Tema.texto, esElegido ? 0.16 : areaMesAnio.containsMouse ? 0.10 : 0.04)
                            border.width: esElegido ? 1 : 0
                            border.color: Tema.conAlfa(Tema.primario, 0.7)

                            MouseArea {
                                id: areaMesAnio
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: vista.irAMes(mesAnio.anio, mesAnio.index)
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4
                                Text {
                                    text: vista.agenda.meses[mesAnio.index].charAt(0).toUpperCase() + vista.agenda.meses[mesAnio.index].slice(1)
                                    color: mesAnio.esActual ? Tema.primario : mes.texto
                                    font { family: mes.fuente; pixelSize: 13; weight: Font.DemiBold }
                                }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    rowSpacing: 1
                                    columnSpacing: 0
                                    Repeater {
                                        model: 42
                                        Item {
                                            required property int index
                                            readonly property string dia: vista.agenda.sumarDias(mesAnio.inicio, index)
                                            readonly property bool delMes: dia.slice(0, 7) === mesAnio.primero.slice(0, 7)
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            implicitHeight: 15
                                            Rectangle {
                                                anchors.centerIn: parent
                                                visible: parent.dia === vista.agenda.dia
                                                width: 15
                                                height: 15
                                                radius: 7.5
                                                color: Tema.primario
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                visible: parent.delMes
                                                text: vista.agenda.fecha(parent.dia).getDate()
                                                color: parent.dia === vista.agenda.dia ? Tema.fondo : mes.tenue
                                                font { family: mes.fuente; pixelSize: 8; features: { "tnum": 1 } }
                                            }
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: !vista.vistaAnio
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: ["LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB", "DOM"]
                            Text {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                leftPadding: 8
                                text: modelData
                                color: mes.tenue
                                font { family: mes.fuente; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.2 }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: 42
                            Rectangle {
                                id: celda
                                required property int index
                                readonly property string dia: vista.agenda.sumarDias(vista.inicio, index)
                                readonly property bool esHoy: dia === vista.agenda.dia
                                readonly property bool esElegido: dia === vista.elegido
                                readonly property bool delMes: dia.slice(0, 7) === vista.mesVisto.slice(0, 7)
                                readonly property var eventos: vista.datos && vista.datos.dias[dia] ? vista.datos.dias[dia] : []

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 1
                                radius: 10
                                color: Tema.conAlfa(Tema.texto, esElegido ? 0.16 : areaCelda.containsMouse ? 0.10 : 0.04)
                                border.width: esElegido ? 1 : 0
                                border.color: Tema.conAlfa(Tema.primario, 0.7)
                                opacity: delMes ? 1 : 0.45

                                MouseArea {
                                    id: areaCelda
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: vista.elegir(celda.dia)
                                    onDoubleClicked: vista.agenda.nuevoEvento(celda.dia)
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 3

                                    Rectangle {
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 11
                                        color: celda.esHoy ? Tema.primario : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: vista.agenda.fecha(celda.dia).getDate()
                                            color: celda.esHoy ? Tema.fondo : mes.texto
                                            font { family: mes.fuente; pixelSize: 12; weight: celda.esHoy ? Font.Bold : Font.Normal; features: { "tnum": 1 } }
                                        }
                                    }

                                    // Hasta 2 eventos como chips; el resto como "+N".
                                    Repeater {
                                        model: celda.eventos.slice(0, celda.eventos.length > 2 ? 1 : 2)
                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: 16
                                            radius: 4
                                            color: Tema.conAlfa(vista.agenda.color(modelData.calendario), modelData.todoElDia ? 0.55 : 0.25)
                                            Text {
                                                anchors.fill: parent
                                                anchors.leftMargin: 5
                                                anchors.rightMargin: 4
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                                text: (parent.modelData.todoElDia ? "" : parent.modelData.inicio + " ") + (parent.modelData.titulo || "(sin título)")
                                                color: mes.texto
                                                font { family: mes.fuente; pixelSize: 9 }
                                            }
                                        }
                                    }
                                    Text {
                                        visible: celda.eventos.length > 2
                                        leftPadding: 4
                                        text: "+" + (celda.eventos.length - 1) + " más"
                                        color: mes.muyTenue
                                        font { family: mes.fuente; pixelSize: 9 }
                                    }
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                    }
                }
            }

            // Día elegido
            Vidrio {
                id: detalle
                solido: true
                width: 320
                height: mes.height

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: vista.tituloDia(vista.elegido)
                        color: detalle.texto
                        font { family: detalle.fuente; pixelSize: 16; weight: Font.DemiBold }
                    }
                    Text {
                        text: (vista.elegido === vista.agenda.dia ? "HOY · " : "") + vista.eventosDia.length + (vista.eventosDia.length === 1 ? " EVENTO" : " EVENTOS")
                        color: detalle.tenue
                        font { family: detalle.fuente; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 1.2 }
                    }

                    Text {
                        visible: !!vista.datos && vista.eventosDia.length === 0
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: vista.datos && !vista.datos.configurado ? "Pega la dirección secreta iCal de tu Google Calendar en ~/.config/escritorio/calendarios.txt" : "Día libre."
                        color: detalle.muyTenue
                        font { family: detalle.fuente; pixelSize: 12; italic: true }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: vista.eventosDia

                        delegate: Rectangle {
                            id: tarjetaEvento
                            required property var modelData
                            width: ListView.view.width
                            implicitHeight: interior.implicitHeight + 20
                            radius: 12
                            color: Tema.conAlfa(Tema.texto, 0.10)
                            border.width: 1
                            border.color: Tema.conAlfa(Tema.texto, 0.14)

                            RowLayout {
                                id: interior
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                Rectangle {
                                    Layout.preferredWidth: 3
                                    Layout.fillHeight: true
                                    radius: 1.5
                                    color: vista.agenda.color(tarjetaEvento.modelData.calendario)
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        text: tarjetaEvento.modelData.titulo || "(sin título)"
                                        color: detalle.texto
                                        font { family: detalle.fuente; pixelSize: 13; weight: Font.DemiBold }
                                    }
                                    Text {
                                        text: tarjetaEvento.modelData.todoElDia ? "Todo el día" : tarjetaEvento.modelData.inicio + (tarjetaEvento.modelData.fin ? " – " + tarjetaEvento.modelData.fin : "")
                                        color: detalle.tenue
                                        font { family: detalle.fuente; pixelSize: 11; features: { "tnum": 1 } }
                                    }
                                    Text {
                                        visible: !!tarjetaEvento.modelData.lugar
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: tarjetaEvento.modelData.lugar
                                        color: detalle.muyTenue
                                        font { family: detalle.fuente; pixelSize: 11 }
                                    }
                                    Text {
                                        visible: vista.datos && vista.datos.calendarios.length > 1
                                        text: vista.datos ? vista.datos.calendarios[tarjetaEvento.modelData.calendario] || "" : ""
                                        color: detalle.muyTenue
                                        font { family: detalle.fuente; pixelSize: 10 }
                                    }
                                }
                            }
                        }
                    }

                    Pildora {
                        Layout.fillWidth: true
                        text: "Nuevo evento este día ›"
                        onPulsado: { vista.agenda.nuevoEvento(vista.elegido); vista.cerrar(); }
                    }
                    Pildora {
                        Layout.fillWidth: true
                        text: "Abrir en Google Calendar ›"
                        onPulsado: { vista.agenda.abrirEnGoogle(vista.elegido); vista.cerrar(); }
                    }
                    Text {
                        visible: !!vista.datos && !!vista.datos.actualizado
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (!vista.datos || !vista.datos.actualizado) return "";
                            const d = new Date(vista.datos.actualizado);
                            return (vista.datos.sinConexion ? "Sin conexión · copia de las " : "Actualizado a las ") + String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
                        }
                        color: vista.datos && vista.datos.sinConexion ? "#ffd27a" : detalle.muyTenue
                        font { family: detalle.fuente; pixelSize: 10 }
                    }
                }
            }
        }
    }

    // Botón redondo (‹ ›), igual al del tablero.
    component Boton: Rectangle {
        property alias text: etiqueta.text
        signal pulsado()
        Layout.alignment: Qt.AlignVCenter
        width: 30
        height: 30
        radius: 15
        color: Tema.conAlfa(Tema.texto, area.containsMouse ? 0.24 : 0.10)
        Text {
            id: etiqueta
            anchors.centerIn: parent
            color: Tema.texto
            font { family: "Inter Variable"; pixelSize: 16; weight: Font.DemiBold }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.pulsado()
        }
    }

    // Botón alargado como "Abrir en Obsidian ›" de la ficha del tablero.
    component Pildora: Rectangle {
        property alias text: etiquetaP.text
        signal pulsado()
        implicitWidth: etiquetaP.implicitWidth + 28
        implicitHeight: 32
        radius: 16
        color: Tema.conAlfa(Tema.texto, areaP.containsMouse ? 0.22 : 0.10)
        Text {
            id: etiquetaP
            anchors.centerIn: parent
            color: Tema.texto
            font { family: "Inter Variable"; pixelSize: 12; weight: Font.DemiBold }
        }
        MouseArea {
            id: areaP
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.pulsado()
        }
    }
}
