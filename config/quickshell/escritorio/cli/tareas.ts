// Pendientes personales: un checklist en Markdown (compatible con Obsidian) que muestran los widgets.
//   - [ ] por hacer   - [/] en curso (continuar)   - [x] hecho
// El archivo se puede editar a mano en Obsidian; aquí solo se tocan las líneas de tareas.
// Una tarea puede terminar en [[Nota]]: el tablero muestra el avance de esa nota.
import { existsSync, readFileSync, renameSync, writeFileSync } from 'node:fs';

export type EstadoTarea = 'pendiente' | 'en-curso' | 'hecha';

export interface Tarea {
  indice: number; // posición entre las tareas del archivo (0, 1, 2…)
  texto: string;
  estado: EstadoTarea;
  nota?: string; // nota del Baúl vinculada, sin corchetes
}

const MARCAS: Record<EstadoTarea, string> = { pendiente: ' ', 'en-curso': '/', hecha: 'x' };
const LINEA_TAREA = /^- \[([ /xX])\] (.+)$/;

const CABECERA = `# Pendientes

Lo que muestran los widgets del escritorio (\`Super+D\`). Para agregar: \`escritorio tarea agregar "texto"\` o escríbelo aquí.
\`[ ]\` por hacer · \`[/]\` en curso · \`[x]\` hecho.

`;

const VINCULO = /\s*\[\[([^\]|#]+)[^\]]*\]\]\s*$/;

// "Texto [[Nota]]" → { texto: "Texto", nota: "Nota" }
const separar = (crudo: string): { texto: string; nota?: string } => {
  const m = crudo.match(VINCULO);
  return m ? { texto: crudo.slice(0, m.index).trim(), nota: m[1].trim() } : { texto: crudo.trim() };
};

const estadoDeMarca = (m: string): EstadoTarea => (m === '/' ? 'en-curso' : m.toLowerCase() === 'x' ? 'hecha' : 'pendiente');

export const parsearTareas = (md: string): Tarea[] =>
  md
    .split('\n')
    .map((l) => l.match(LINEA_TAREA))
    .filter((m): m is RegExpMatchArray => !!m)
    .map((m, indice) => ({ indice, ...separar(m[2]), estado: estadoDeMarca(m[1]) }))
    .map(({ indice, texto, estado, nota }) => (nota ? { indice, texto, estado, nota } : { indice, texto, estado }));

export const leerTareas = (ruta: string): Tarea[] => (existsSync(ruta) ? parsearTareas(readFileSync(ruta, 'utf8')) : []);

const escribir = (ruta: string, md: string) => {
  writeFileSync(`${ruta}.tmp`, md);
  renameSync(`${ruta}.tmp`, ruta);
};

export const agregarTarea = (md: string, texto: string, estado: EstadoTarea = 'pendiente', nota?: string): string => {
  const limpio = texto.replace(/\s+/g, ' ').trim();
  if (!limpio) throw new Error('La tarea está vacía');
  const base = md.trim() ? `${md.trimEnd()}\n` : CABECERA;
  return `${base}- [${MARCAS[estado]}] ${limpio}${nota ? ` [[${nota.trim()}]]` : ''}\n`;
};

// Cambia el estado de la tarea `indice`. Si se pasa `texto`, debe coincidir: evita marcar otra
// tarea cuando el archivo cambió (por ejemplo, editado en Obsidian) entre la lectura y el clic.
export const cambiarEstado = (md: string, indice: number, estado: EstadoTarea, texto?: string): string => {
  let n = -1;
  let encontrada = false;
  const lineas = md.split('\n').map((linea) => {
    const m = linea.match(LINEA_TAREA);
    if (!m || ++n !== indice) return linea;
    if (texto !== undefined && separar(m[2]).texto !== texto) throw new Error('La lista cambió; vuelve a intentarlo');
    encontrada = true;
    return `- [${MARCAS[estado]}] ${m[2]}`;
  });
  if (!encontrada) throw new Error(`No existe la tarea ${indice}`);
  return lineas.join('\n');
};

export const guardarNuevaTarea = (ruta: string, texto: string, estado?: EstadoTarea, nota?: string) =>
  escribir(ruta, agregarTarea(existsSync(ruta) ? readFileSync(ruta, 'utf8') : '', texto, estado, nota));

export const guardarEstadoTarea = (ruta: string, indice: number, estado: EstadoTarea, texto?: string) =>
  escribir(ruta, cambiarEstado(readFileSync(ruta, 'utf8'), indice, estado, texto));
