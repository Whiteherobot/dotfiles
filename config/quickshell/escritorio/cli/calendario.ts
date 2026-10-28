// Calendario de Google por su "dirección secreta en formato iCal" (solo lectura, sin OAuth).
// Las direcciones van en ~/.config/escritorio/calendarios.txt, una por línea ("Nombre | https://…"),
// fuera del repo porque dan acceso al calendario. Se guarda una copia en ~/.cache/escritorio para
// que el widget siga mostrando algo sin conexión.
//
// Soporta lo que Google exporta en la práctica: eventos con hora (UTC o TZID), de día completo,
// repetidos (RRULE DAILY/WEEKLY/MONTHLY/YEARLY con INTERVAL, COUNT, UNTIL, BYDAY, BYMONTHDAY),
// EXDATE, ocurrencias editadas (RECURRENCE-ID) y canceladas.
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { config } from './config.ts';
import { hoyLocal, sumarDias } from './fechas.ts';

export interface Calendario {
  nombre: string;
  url: string;
}

export interface EventoDia {
  inicio: string | null; // "HH:MM" local; null si es de día completo
  fin: string | null;
  titulo: string;
  lugar: string;
  todoElDia: boolean;
  calendario: number; // índice en la lista de calendarios (para el color)
}

interface Momento {
  fecha: string; // YYYY-MM-DD en la zona del evento
  hora: [number, number, number] | null; // null = día completo
  tz: string | null; // null = UTC si utc, o flotante (hora local)
  utc: boolean;
}

interface VEvento {
  uid: string;
  titulo: string;
  lugar: string;
  estado: string;
  inicio: Momento;
  duracionMs: number;
  duracionDias: number; // para los de día completo
  rrule: Record<string, string> | null;
  exdates: number[];
  recurrenceId: number | null;
}

// ---------- Lectura del .ics ----------

const desescapar = (v: string) => v.replace(/\\n/gi, '\n').replace(/\\([,;\\])/g, '$1');

function lineas(ics: string): { nombre: string; params: Record<string, string>; valor: string }[] {
  // Las líneas largas siguen en la siguiente si esta empieza con espacio o tab.
  const juntas = ics.replace(/\r\n/g, '\n').replace(/\n[ \t]/g, '').split('\n');
  return juntas.filter(Boolean).map((l) => {
    const dos = l.indexOf(':');
    const cabeza = dos < 0 ? l : l.slice(0, dos);
    const [nombre, ...ps] = cabeza.split(';');
    const params: Record<string, string> = {};
    for (const p of ps) {
      const [k, v = ''] = p.split('=');
      params[k.toUpperCase()] = v.replace(/^"|"$/g, '');
    }
    return { nombre: nombre.toUpperCase(), params, valor: dos < 0 ? '' : l.slice(dos + 1) };
  });
}

function leerMomento(valor: string, params: Record<string, string>): Momento {
  const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/.exec(valor.trim());
  if (!m) throw new Error(`Fecha iCal inválida: ${valor}`);
  const fecha = `${m[1]}-${m[2]}-${m[3]}`;
  if (!m[4] || params.VALUE === 'DATE') return { fecha, hora: null, tz: null, utc: false };
  return { fecha, hora: [Number(m[4]), Number(m[5]), Number(m[6])], tz: m[7] ? null : (params.TZID ?? null), utc: !!m[7] };
}

function leerDuracion(v: string): { ms: number; dias: number } {
  const m = /^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec(v.trim());
  if (!m) return { ms: 0, dias: 0 };
  const dias = Number(m[2] ?? 0) * 7 + Number(m[3] ?? 0);
  const ms = ((dias * 24 + Number(m[4] ?? 0)) * 60 + Number(m[5] ?? 0)) * 60_000 + Number(m[6] ?? 0) * 1000;
  return { ms, dias };
}

// Desfase de una zona IANA en un instante (ms a sumar a UTC para tener la hora de pared).
function desfase(ms: number, tz: string): number {
  try {
    const partes = new Intl.DateTimeFormat('en-US', {
      timeZone: tz, hourCycle: 'h23', year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
    }).formatToParts(new Date(ms));
    const p = Object.fromEntries(partes.map((x) => [x.type, Number(x.value)]));
    return Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second) - Math.floor(ms / 1000) * 1000;
  } catch {
    return -new Date(ms).getTimezoneOffset() * 60_000; // zona desconocida: la local
  }
}

// Instante (ms) de un momento. Los de día completo caen a la medianoche local.
export function aMs(m: Momento): number {
  const [a, mes, d] = m.fecha.split('-').map(Number);
  if (!m.hora) return new Date(a, mes - 1, d).getTime();
  const [h, mi, s] = m.hora;
  if (m.utc) return Date.UTC(a, mes - 1, d, h, mi, s);
  if (!m.tz) return new Date(a, mes - 1, d, h, mi, s).getTime();
  const pared = Date.UTC(a, mes - 1, d, h, mi, s);
  let ms = pared - desfase(pared, m.tz);
  ms = pared - desfase(ms, m.tz); // segunda pasada por si cruza un cambio de horario
  return ms;
}

export function parsearIcs(ics: string): VEvento[] {
  const eventos: VEvento[] = [];
  let actual: Partial<VEvento> & { fin?: Momento; dur?: { ms: number; dias: number } } | null = null;
  let anidado = 0; // VALARM dentro de VEVENT
  for (const { nombre, params, valor } of lineas(ics)) {
    if (nombre === 'BEGIN' && valor === 'VEVENT') {
      actual = { titulo: '', lugar: '', estado: '', exdates: [], rrule: null, recurrenceId: null };
      continue;
    }
    if (!actual) continue;
    if (nombre === 'BEGIN') { anidado++; continue; }
    if (nombre === 'END' && valor !== 'VEVENT') { anidado--; continue; }
    if (anidado > 0) continue;
    if (nombre === 'END') {
      if (actual.inicio && actual.uid) {
        const ini = actual.inicio;
        let duracionMs = 0;
        let duracionDias = ini.hora ? 0 : 1;
        if (actual.fin) {
          if (ini.hora) duracionMs = aMs(actual.fin) - aMs(ini);
          else duracionDias = Math.max(1, Math.round((Date.parse(actual.fin.fecha) - Date.parse(ini.fecha)) / 86_400_000));
        } else if (actual.dur) {
          duracionMs = actual.dur.ms;
          if (!ini.hora) duracionDias = Math.max(1, actual.dur.dias);
        }
        eventos.push({
          uid: actual.uid, titulo: actual.titulo ?? '', lugar: actual.lugar ?? '', estado: actual.estado ?? '',
          inicio: ini, duracionMs, duracionDias, rrule: actual.rrule ?? null,
          exdates: actual.exdates ?? [], recurrenceId: actual.recurrenceId ?? null,
        });
      }
      actual = null;
      continue;
    }
    switch (nombre) {
      case 'UID': actual.uid = valor; break;
      case 'SUMMARY': actual.titulo = desescapar(valor); break;
      case 'LOCATION': actual.lugar = desescapar(valor); break;
      case 'STATUS': actual.estado = valor.toUpperCase(); break;
      case 'DTSTART': actual.inicio = leerMomento(valor, params); break;
      case 'DTEND': actual.fin = leerMomento(valor, params); break;
      case 'DURATION': actual.dur = leerDuracion(valor); break;
      case 'RRULE':
        actual.rrule = Object.fromEntries(valor.split(';').map((p) => p.split('=') as [string, string]).map(([k, v]) => [k.toUpperCase(), v]));
        break;
      case 'EXDATE':
        for (const v of valor.split(',')) actual.exdates!.push(aMs(leerMomento(v, params)));
        break;
      case 'RECURRENCE-ID': actual.recurrenceId = aMs(leerMomento(valor, params)); break;
    }
  }
  return eventos;
}

// ---------- Repeticiones ----------

const DIAS_ICS = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
const diaDe = (f: string) => new Date(Date.parse(f)).getUTCDay();
const finDeMes = (a: number, m: number) => new Date(Date.UTC(a, m, 0)).getUTCDate(); // m: 1-12
const p2 = (n: number) => String(n).padStart(2, '0');

function sumarMeses(fecha: string, n: number): [number, number] {
  const [a, m] = fecha.split('-').map(Number);
  const total = a * 12 + (m - 1) + n;
  return [Math.floor(total / 12), (total % 12) + 1];
}

// Días del mes que cumplen BYDAY (con ordinal: 2TU, -1FR) o BYMONTHDAY.
function diasDelMes(a: number, m: number, regla: Record<string, string>, diaBase: number): string[] {
  const ultimo = finDeMes(a, m);
  const dias = new Set<number>();
  if (regla.BYDAY) {
    for (const t of regla.BYDAY.split(',')) {
      const x = /^([+-]?\d+)?([A-Z]{2})$/.exec(t);
      if (!x) continue;
      const dow = DIAS_ICS.indexOf(x[2]);
      const coinciden: number[] = [];
      for (let d = 1; d <= ultimo; d++) if (new Date(Date.UTC(a, m - 1, d)).getUTCDay() === dow) coinciden.push(d);
      if (!x[1]) coinciden.forEach((d) => dias.add(d));
      else {
        const n = Number(x[1]);
        const d = n > 0 ? coinciden[n - 1] : coinciden[coinciden.length + n];
        if (d) dias.add(d);
      }
    }
  } else {
    const lista = regla.BYMONTHDAY ? regla.BYMONTHDAY.split(',').map(Number) : [diaBase];
    for (const d of lista) {
      const real = d < 0 ? ultimo + d + 1 : d;
      if (real >= 1 && real <= ultimo) dias.add(real);
    }
  }
  return [...dias].sort((x, y) => x - y).map((d) => `${a}-${p2(m)}-${p2(d)}`);
}

// Fechas (en la zona del evento) de cada ocurrencia hasta `hasta`, respetando COUNT y UNTIL.
function fechasDeRegla(ev: VEvento, hasta: string): string[] {
  const r = ev.rrule!;
  const inicio = ev.inicio.fecha;
  const intervalo = Math.max(1, Number(r.INTERVAL ?? 1));
  const cuenta = r.COUNT ? Number(r.COUNT) : Infinity;
  const hastaMs = r.UNTIL ? aMs(leerMomento(r.UNTIL, {})) : Infinity;
  const fechas: string[] = [];
  const aceptar = (f: string): boolean => {
    if (f < inicio) return true;
    if (f > hasta || fechas.length >= cuenta) return false;
    if (aMs({ ...ev.inicio, fecha: f }) > hastaMs) return false;
    fechas.push(f);
    return true;
  };
  const [a0, m0, d0] = inicio.split('-').map(Number);
  for (let paso = 0; paso < 20000; paso++) {
    let lote: string[];
    switch (r.FREQ) {
      case 'DAILY': lote = [sumarDias(inicio, paso * intervalo)]; break;
      case 'WEEKLY': {
        // Semanas que empiezan el lunes (WKST=MO, lo que usa Google).
        const lunes = sumarDias(inicio, -((diaDe(inicio) + 6) % 7) + paso * 7 * intervalo);
        const dias = r.BYDAY ? r.BYDAY.split(',').map((t) => DIAS_ICS.indexOf(t.slice(-2))) : [diaDe(inicio)];
        lote = dias.map((dow) => sumarDias(lunes, (dow + 6) % 7)).sort();
        break;
      }
      case 'MONTHLY': {
        const [a, m] = sumarMeses(inicio, paso * intervalo);
        lote = diasDelMes(a, m, r, d0);
        break;
      }
      case 'YEARLY': {
        const a = a0 + paso * intervalo;
        const m = r.BYMONTH ? Number(r.BYMONTH) : m0;
        lote = r.BYDAY || r.BYMONTHDAY ? diasDelMes(a, m, r, d0) : d0 <= finDeMes(a, m) ? [`${a}-${p2(m)}-${p2(d0)}`] : [];
        break;
      }
      default: return [inicio];
    }
    for (const f of lote) if (!aceptar(f)) return fechas;
  }
  return fechas;
}

// ---------- Eventos por día ----------

const horaLocal = (ms: number) => {
  const d = new Date(ms);
  return `${p2(d.getHours())}:${p2(d.getMinutes())}`;
};

export function eventosPorDia(eventos: VEvento[], desde: string, hasta: string, calendario = 0): Record<string, EventoDia[]> {
  const dias: Record<string, EventoDia[]> = {};
  const editadas = new Map<string, Set<number>>();
  for (const e of eventos) if (e.recurrenceId !== null) {
    if (!editadas.has(e.uid)) editadas.set(e.uid, new Set());
    editadas.get(e.uid)!.add(e.recurrenceId);
  }
  // Margen para eventos que empiezan antes y siguen dentro del rango.
  const tope = sumarDias(hasta, 1);
  const desdeMs = aMs({ fecha: desde, hora: null, tz: null, utc: false });
  const hastaMs = aMs({ fecha: tope, hora: null, tz: null, utc: false });

  const poner = (e: VEvento, inicioMs: number) => {
    if (e.inicio.hora) {
      const finMs = inicioMs + e.duracionMs;
      if (finMs < desdeMs || inicioMs >= hastaMs) return;
      // Un evento con hora que cruza la medianoche aparece en cada día que toca.
      let f = hoyLocal(new Date(inicioMs));
      const ultimo = hoyLocal(new Date(Math.max(inicioMs, finMs - 1)));
      for (let i = 0; i < 31 && f <= ultimo; i++, f = sumarDias(f, 1)) {
        if (f < desde || f > hasta) continue;
        (dias[f] ??= []).push({ inicio: horaLocal(inicioMs), fin: e.duracionMs ? horaLocal(finMs) : null, titulo: e.titulo, lugar: e.lugar, todoElDia: false, calendario });
      }
    } else {
      const primero = hoyLocal(new Date(inicioMs));
      for (let i = 0; i < Math.min(e.duracionDias, 366); i++) {
        const f = sumarDias(primero, i);
        if (f < desde || f > hasta) continue;
        (dias[f] ??= []).push({ inicio: null, fin: null, titulo: e.titulo, lugar: e.lugar, todoElDia: true, calendario });
      }
    }
  };

  for (const e of eventos) {
    if (e.estado === 'CANCELLED') continue;
    if (e.recurrenceId !== null || !e.rrule) {
      poner(e, aMs(e.inicio));
      continue;
    }
    const excluir = new Set([...e.exdates, ...(editadas.get(e.uid) ?? [])]);
    for (const f of fechasDeRegla(e, tope)) {
      const ms = aMs({ ...e.inicio, fecha: f });
      if (!excluir.has(ms)) poner(e, ms);
    }
  }
  for (const lista of Object.values(dias))
    lista.sort((x, y) => Number(y.todoElDia) - Number(x.todoElDia) || (x.inicio ?? '').localeCompare(y.inicio ?? '') || x.titulo.localeCompare(y.titulo));
  return dias;
}

// ---------- Configuración, descarga y caché ----------

const archivoConfig = config.calendarios;
const carpetaCache = config.cache;

export function leerCalendarios(texto: string): Calendario[] {
  return texto.split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#')).map((l, i) => {
    const [a, b] = l.includes('|') ? l.split('|').map((x) => x.trim()) : [`Calendario ${i + 1}`, l];
    return { nombre: a, url: b.replace(/^webcal:\/\//i, 'https://') };
  });
}

async function descargar(cal: Calendario, i: number, forzar: boolean): Promise<{ ics: string; sinConexion: boolean; cuando: number }> {
  const cache = join(carpetaCache, `calendario-${i}.ics`);
  const fresca = existsSync(cache) && Date.now() - statSync(cache).mtimeMs < 10 * 60_000;
  if (fresca && !forzar) return { ics: readFileSync(cache, 'utf8'), sinConexion: false, cuando: statSync(cache).mtimeMs };
  try {
    const r = await fetch(cal.url, { signal: AbortSignal.timeout(10_000) });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const ics = await r.text();
    if (!ics.includes('BEGIN:VCALENDAR')) throw new Error('La dirección no devolvió un calendario iCal');
    mkdirSync(carpetaCache, { recursive: true });
    writeFileSync(cache, ics);
    return { ics, sinConexion: false, cuando: Date.now() };
  } catch (e) {
    if (existsSync(cache)) return { ics: readFileSync(cache, 'utf8'), sinConexion: true, cuando: statSync(cache).mtimeMs };
    throw e;
  }
}

// Rango por defecto: la cuadrícula del mes actual (6 semanas desde el lunes) y al menos 14 días adelante.
export function rangoPorDefecto(hoy: string): [string, string] {
  const primero = hoy.slice(0, 8) + '01';
  const desde = sumarDias(primero, -((diaDe(primero) + 6) % 7));
  const hasta = [sumarDias(desde, 41), sumarDias(hoy, 14)].sort()[1];
  return [desde, hasta];
}

export async function consultarCalendario(desde: string, hasta: string, forzar = false) {
  const calendarios = existsSync(archivoConfig) ? leerCalendarios(readFileSync(archivoConfig, 'utf8')) : [];
  const dias: Record<string, EventoDia[]> = {};
  const errores: string[] = [];
  let sinConexion = false;
  let actualizado = 0;
  for (const [i, cal] of calendarios.entries()) {
    try {
      const d = await descargar(cal, i, forzar);
      sinConexion ||= d.sinConexion;
      actualizado = Math.max(actualizado, d.cuando);
      for (const [f, lista] of Object.entries(eventosPorDia(parsearIcs(d.ics), desde, hasta, i))) (dias[f] ??= []).push(...lista);
    } catch (e) {
      errores.push(`${cal.nombre}: ${(e as Error).message}`);
    }
  }
  for (const lista of Object.values(dias))
    lista.sort((x, y) => Number(y.todoElDia) - Number(x.todoElDia) || (x.inicio ?? '').localeCompare(y.inicio ?? ''));
  return {
    configurado: calendarios.length > 0,
    archivo: archivoConfig,
    calendarios: calendarios.map((c) => c.nombre),
    desde,
    hasta,
    actualizado: actualizado ? new Date(actualizado).toISOString() : null,
    sinConexion,
    errores,
    dias,
  };
}
