// Resumen del avance de una nota (Obsidian) para el tablero de pendientes: el aviso de estado
// (primer callout), el checklist de la nota y las secciones de estado/avance/pendiente/historial.
// Solo lee: la nota sigue siendo la fuente de verdad y se edita en Obsidian.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

export interface Seccion {
  titulo: string;
  texto: string; // Markdown sin wikilinks
}

export interface Detalle {
  nota: string;
  ruta: string;
  modificada: string; // YYYY-MM-DD
  aviso?: { tipo: string; texto: string };
  checklist?: { hechos: number; total: number; siguientes: string[] };
  secciones: Seccion[];
}

const SECCION_AVANCE = /estado|avance|progreso|listo|pendiente|pr[oó]ximo|siguiente|historial|bit[aá]cora|resultados/i;
const SECCION_HISTORIAL = /historial|bit[aá]cora/i;
const MAX_LINEAS = 12;
const MAX_HISTORIAL = 6;

// [[Nota|alias]] → alias, [[Nota#Título]] → Nota
export const limpiar = (md: string) =>
  md.replace(/\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|([^\]]+))?\]\]/g, (_, nota: string, alias?: string) => alias ?? nota);

const recortar = (lineas: string[], historial: boolean) => {
  const utiles = lineas.filter((l) => l.trim());
  // Del historial interesa lo último; del resto, lo primero.
  if (historial) return utiles.length > MAX_HISTORIAL ? ['…', ...utiles.slice(-MAX_HISTORIAL)] : utiles;
  return utiles.length > MAX_LINEAS ? [...utiles.slice(0, MAX_LINEAS), '…'] : utiles;
};

export const resumirNota = (md: string): Pick<Detalle, 'aviso' | 'checklist' | 'secciones'> => {
  const lineas = md.split('\n');

  // Primer callout: "> [!success] Estado: …" y sus líneas "> …"
  let aviso: Detalle['aviso'];
  const inicio = lineas.findIndex((l) => /^> \[!\w+\]/.test(l));
  if (inicio >= 0) {
    const tipo = lineas[inicio].match(/^> \[!(\w+)\]/)![1].toLowerCase();
    const cuerpo = [lineas[inicio].replace(/^> \[!\w+\][-+]?\s*/, '')];
    for (let i = inicio + 1; i < lineas.length && lineas[i].startsWith('>'); i++) cuerpo.push(lineas[i].replace(/^>\s?/, ''));
    aviso = { tipo, texto: limpiar(cuerpo.join('\n').trim()) };
  }

  const casillas = lineas.map((l) => l.match(/^\s*- \[([ xX/])\] (.+)$/)).filter((m): m is RegExpMatchArray => !!m);
  const checklist = casillas.length
    ? {
        hechos: casillas.filter((m) => m[1].toLowerCase() === 'x').length,
        total: casillas.length,
        siguientes: casillas.filter((m) => m[1].toLowerCase() !== 'x').slice(0, 5).map((m) => limpiar(m[2].trim())),
      }
    : undefined;

  // Secciones "## …": las de avance; si no hay ninguna, la primera (contexto/objetivo).
  const todas: { titulo: string; lineas: string[] }[] = [];
  for (const l of lineas) {
    const h = l.match(/^## (.+)$/);
    if (h) todas.push({ titulo: limpiar(h[1].trim()), lineas: [] });
    else if (todas.length) todas.at(-1)!.lineas.push(l);
  }
  const deAvance = todas.filter((s) => SECCION_AVANCE.test(s.titulo) && !/relacionad/i.test(s.titulo));
  const elegidas = deAvance.length ? deAvance : todas.slice(0, 1);
  const secciones = elegidas
    .map((s) => ({ titulo: s.titulo, texto: limpiar(recortar(s.lineas, SECCION_HISTORIAL.test(s.titulo)).join('\n')) }))
    // Los "### …" internos se ven enormes en la ficha: pasan a negrita.
    .map((s) => ({ ...s, texto: s.texto.replace(/^#{3,6} (.+)$/gm, '**$1**') }))
    .filter((s) => s.texto);

  return { aviso, checklist, secciones };
};

// Busca "<nota>.md" dentro del vault (sin carpetas ocultas como .obsidian o .stversions).
export const buscarNota = (raiz: string, nota: string): string | undefined => {
  if (!existsSync(raiz)) return undefined;
  for (const nombre of readdirSync(raiz)) {
    if (nombre.startsWith('.')) continue;
    const ruta = join(raiz, nombre);
    if (nombre === `${nota}.md`) return ruta;
    if (statSync(ruta).isDirectory()) {
      const r = buscarNota(ruta, nota);
      if (r) return r;
    }
  }
  return undefined;
};

export const detalleDeNota = (raiz: string, nota: string): Detalle | undefined => {
  const ruta = buscarNota(raiz, nota);
  if (!ruta) return undefined;
  const m = statSync(ruta).mtime;
  const modificada = `${m.getFullYear()}-${String(m.getMonth() + 1).padStart(2, '0')}-${String(m.getDate()).padStart(2, '0')}`;
  return { nota, ruta, modificada, ...resumirNota(readFileSync(ruta, 'utf8')) };
};
