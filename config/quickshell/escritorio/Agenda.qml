// Fuente de datos del calendario: corre `escritorio calendario` (Google Calendar por iCal).
// `datos` es la cuadrícula del mes actual + 2 semanas (tarjeta); `mes` es el rango que pide la vista grande.
// Se refresca cada 10 min (la CLI guarda copia y no descarga más seguido) y al cambiar la configuración.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var estado
    property var datos: null
    property var mes: null
    // Hoy ("YYYY-MM-DD"); cambia a medianoche y con eso se actualizan las vistas.
    property string dia: iso(new Date())

    // Pide abrir la vista grande en una fecha ("YYYY-MM-DD"); con `anio` abre los 12 meses.
    signal pidioCalendario(string fecha, bool anio)

    // Colores por calendario (índice en calendarios.txt): el primario del tema y luego tonos fijos.
    readonly property var colores: [Tema.primario, "#d7ab5b", "#5b9dd7", "#c07878", "#8fbf7f"]
    readonly property var meses: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
    readonly property var diasSemana: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]

    function color(i) {
        return colores[i % colores.length];
    }

    function iso(d) {
        const p = n => String(n).padStart(2, "0");
        return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate());
    }

    function fecha(texto) {
        const [a, m, d] = texto.split("-").map(Number);
        return new Date(a, m - 1, d);
    }

    function hoy() {
        return iso(new Date());
    }

    function sumarDias(texto, n) {
        const d = fecha(texto);
        d.setDate(d.getDate() + n);
        return iso(d);
    }

    // Lunes de la semana del día 1 del mes de `texto`: inicio de la cuadrícula de 6 semanas.
    function inicioCuadricula(texto) {
        const d = fecha(texto.slice(0, 8) + "01");
        d.setDate(d.getDate() - (d.getDay() + 6) % 7);
        return iso(d);
    }

    function nombreMes(texto) {
        const d = fecha(texto);
        return meses[d.getMonth()];
    }

    // "Hoy", "Mañana", "Lunes 26"…
    function diaRelativo(texto) {
        const dif = Math.round((fecha(texto) - fecha(hoy())) / 86400000);
        if (dif === 0) return "Hoy";
        if (dif === 1) return "Mañana";
        const d = fecha(texto);
        const n = diasSemana[d.getDay()];
        return n.charAt(0).toUpperCase() + n.slice(1) + " " + d.getDate();
    }

    function abrir(texto, anio) {
        pidioCalendario(texto || hoy(), !!anio);
        estado.abrio();
    }

    function refrescar(forzar) {
        if (proceso.running) return;
        proceso.command = [estado.cli, "calendario"].concat(forzar ? ["--forzar"] : []);
        proceso.running = true;
    }

    function cargarMes(texto) {
        const desde = inicioCuadricula(texto);
        procesoMes.command = [estado.cli, "calendario", "--desde", desde, "--hasta", sumarDias(desde, 41)];
        procesoMes.running = true;
    }

    // "Nuevo evento" abre el formulario de Google con el día ya puesto.
    function nuevoEvento(texto) {
        const a = texto.replace(/-/g, "");
        const b = sumarDias(texto, 1).replace(/-/g, "");
        Quickshell.execDetached(["xdg-open", "https://calendar.google.com/calendar/render?action=TEMPLATE&dates=" + a + "/" + b]);
    }

    function abrirEnGoogle(texto) {
        Quickshell.execDetached(["xdg-open", "https://calendar.google.com/calendar/r/day/" + texto.replace(/-/g, "/")]);
    }

    Process {
        id: proceso
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.datos = JSON.parse(text);
                } catch (e) {
                    console.warn("escritorio calendario:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("escritorio calendario:", text)
        }
    }

    Process {
        id: procesoMes
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.mes = JSON.parse(text);
                } catch (e) {
                    console.warn("escritorio calendario (mes):", e);
                }
            }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/escritorio/calendarios.txt"
        watchChanges: true
        onFileChanged: root.refrescar(true)
    }

    Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refrescar(false)
    }

    // A medianoche cambia "hoy": se vuelve a pedir el rango.
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: if (root.hoy() !== root.dia) { root.dia = root.hoy(); root.refrescar(false); }
    }
}
