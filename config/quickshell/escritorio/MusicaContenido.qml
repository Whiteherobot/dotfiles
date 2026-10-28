// Tarjeta "Ahora suena" estilo widget de macOS: carátula, título, artista, barras de audio, progreso
// y controles del reproductor activo (Apple Music, Spotify, YouTube, mpv… por MPRIS). El fondo se tiñe
// con la carátula desenfocada. Sin nada sonando, la tarjeta se oculta.
// Con `ancho` > 500 (panel) usa el modo ancho: carátula grande, controles a la derecha y barras altas.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets

Vidrio {
    id: tarjeta

    property int ancho: 346
    readonly property bool ancha: ancho > 500

    // El que está sonando; si ninguno, el último con canción (en pausa). Los que no tienen título
    // (p. ej. WhatsApp web abierto) no cuentan.
    readonly property var jugador: {
        const conPista = Mpris.players.values.filter(p => p.trackTitle);
        return conPista.find(p => p.isPlaying) || conPista[0] || null;
    }
    readonly property bool sonando: !!jugador && jugador.isPlaying
    readonly property bool conDuracion: !!jugador && jugador.lengthSupported && jugador.length > 0 && jugador.length < 86400
    readonly property string fuenteIconos: "JetBrainsMono Nerd Font"

    // Barras de audio del cava compartido (Espectro.qml).
    readonly property int barras: Espectro.barras
    readonly property var niveles: Espectro.niveles

    function tiempo(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    visible: !!jugador
    implicitWidth: ancho
    implicitHeight: contenido.implicitHeight + 36

    // MPRIS no avisa cada segundo del avance: se pide mientras suena.
    Timer {
        running: tarjeta.sonando && tarjeta.visible
        interval: 1000
        repeat: true
        onTriggered: tarjeta.jugador.positionChanged()
    }

    // Carátula desenfocada de fondo, recortada al borde redondeado de la tarjeta.
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: tarjeta.radius - 1
        color: "transparent"
        visible: fondo.status === Image.Ready

        Image {
            id: fondo
            anchors.fill: parent
            source: tarjeta.jugador ? tarjeta.jugador.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 128
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: fondo
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.2
            opacity: tarjeta.solido ? 0.30 : 0.42
        }
        // Velo para que el texto se lea sobre carátulas claras.
        Rectangle {
            anchors.fill: parent
            color: Tema.conAlfa(Tema.fondo, 0.35)
        }
    }

    ColumnLayout {
        id: contenido
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: tarjeta.ancha ? 18 : 14

            ClippingRectangle {
                implicitWidth: tarjeta.ancha ? 88 : 64
                implicitHeight: implicitWidth
                radius: tarjeta.ancha ? 14 : 12
                color: Tema.conAlfa(Tema.texto, 0.12)

                Image {
                    id: caratula
                    anchors.fill: parent
                    source: tarjeta.jugador ? tarjeta.jugador.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 192
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: caratula.status !== Image.Ready
                    text: "󰎆"
                    color: tarjeta.tenue
                    font { family: tarjeta.fuenteIconos; pixelSize: tarjeta.ancha ? 34 : 26 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: tarjeta.jugador ? tarjeta.jugador.trackTitle : ""
                    color: tarjeta.texto
                    font { family: tarjeta.fuente; pixelSize: tarjeta.ancha ? 17 : 14; weight: Font.DemiBold }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    elide: Text.ElideRight
                    text: tarjeta.jugador ? tarjeta.jugador.trackArtist : ""
                    color: tarjeta.tenue
                    font { family: tarjeta.fuente; pixelSize: tarjeta.ancha ? 13 : 12 }
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: !tarjeta.jugador ? "" : (tarjeta.sonando ? "" : "En pausa · ") + (tarjeta.jugador.identity || "Reproductor")
                    color: tarjeta.muyTenue
                    font { family: tarjeta.fuente; pixelSize: 10 }
                }
            }

            // En el modo ancho los controles van a la derecha del título.
            Item {
                id: huecoDerecha
                visible: tarjeta.ancha
                implicitWidth: controles.implicitWidth
                implicitHeight: controles.implicitHeight
            }
        }

        // Barras de audio con un solo degradado de abajo hacia arriba (las altas llegan al color de arriba).
        Item {
            id: visual
            Layout.fillWidth: true
            implicitHeight: tarjeta.ancha ? 110 : 56

            Item {
                id: mascara
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Row {
                    id: fila
                    anchors.bottom: parent.bottom
                    spacing: tarjeta.ancha ? 6 : 3
                    readonly property real anchoBarra: (visual.width - spacing * (tarjeta.barras - 1)) / tarjeta.barras

                    Repeater {
                        model: tarjeta.barras
                        Rectangle {
                            required property int index
                            anchors.bottom: parent.bottom
                            width: fila.anchoBarra
                            height: Math.max(3, (tarjeta.niveles[index] || 0) / 100 * visual.height)
                            radius: Math.min(3, width / 2)
                            color: "white"
                            Behavior on height { NumberAnimation { duration: 60 } }
                        }
                    }
                }
            }

            Rectangle {
                id: degradado
                anchors.fill: parent
                visible: false
                layer.enabled: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Tema.brilloArriba }
                    GradientStop { position: 0.5; color: Tema.brilloMedio }
                    GradientStop { position: 1.0; color: Tema.primario }
                }
            }

            MultiEffect {
                anchors.fill: parent
                source: degradado
                maskEnabled: true
                maskSource: mascara
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                opacity: tarjeta.sonando ? 0.95 : 0.4
            }
        }

        // Progreso (clic para saltar si el reproductor lo permite)
        ColumnLayout {
            Layout.fillWidth: true
            visible: tarjeta.conDuracion
            spacing: 4

            Rectangle {
                id: barra
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Tema.conAlfa(Tema.texto, 0.18)
                Rectangle {
                    height: parent.height
                    radius: 2
                    color: tarjeta.texto
                    width: tarjeta.conDuracion ? Math.min(1, tarjeta.jugador.position / tarjeta.jugador.length) * parent.width : 0
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    enabled: !!tarjeta.jugador && tarjeta.jugador.canSeek
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: e => tarjeta.jugador.position = e.x / barra.width * tarjeta.jugador.length
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: tarjeta.conDuracion ? tarjeta.tiempo(tarjeta.jugador.position) : ""
                    color: tarjeta.muyTenue
                    font { family: tarjeta.fuente; pixelSize: 10; features: { "tnum": 1 } }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: tarjeta.conDuracion ? "-" + tarjeta.tiempo(tarjeta.jugador.length - tarjeta.jugador.position) : ""
                    color: tarjeta.muyTenue
                    font { family: tarjeta.fuente; pixelSize: 10; features: { "tnum": 1 } }
                }
            }
        }

        Item {
            id: huecoAbajo
            visible: !tarjeta.ancha
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: controles.implicitWidth
            implicitHeight: controles.implicitHeight
        }
    }

    component Mando: Rectangle {
        property string icono
        property bool grande: false
        property bool activo: true
        signal pulsado()
        implicitWidth: grande ? 40 : 32
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        color: Tema.conAlfa(Tema.texto, grande ? (area.containsMouse ? 0.26 : 0.16) : (area.containsMouse ? 0.14 : 0))
        opacity: activo ? 1 : 0.35
        Text {
            anchors.centerIn: parent
            text: parent.icono
            color: Tema.texto
            font { family: tarjeta.fuenteIconos; pixelSize: parent.grande ? 20 : 17 }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            enabled: parent.activo
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.pulsado()
        }
    }

    // Un solo juego de controles que se muda al hueco que toca según el ancho.
    RowLayout {
        id: controles
        parent: tarjeta.ancha ? huecoDerecha : huecoAbajo
        anchors.centerIn: parent
        spacing: 22
        Mando {
            icono: "󰒮"
            activo: !!tarjeta.jugador && tarjeta.jugador.canGoPrevious
            onPulsado: tarjeta.jugador.previous()
        }
        Mando {
            icono: tarjeta.sonando ? "󰏤" : "󰐊"
            grande: true
            activo: !!tarjeta.jugador && tarjeta.jugador.canTogglePlaying
            onPulsado: tarjeta.jugador.togglePlaying()
        }
        Mando {
            icono: "󰒭"
            activo: !!tarjeta.jugador && tarjeta.jugador.canGoNext
            onPulsado: tarjeta.jugador.next()
        }
    }
}
