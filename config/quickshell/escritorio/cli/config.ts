import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

// Configuración local, fuera del repo: ~/.config/escritorio/config.json
//   { "pendientes": "~/ruta/Pendientes.md", "notas": "~/ruta/del/vault" }
// "notas" es la carpeta donde se buscan las [[Notas]] vinculadas a una tarea (por defecto, la del archivo).
const carpeta = process.env.ESCRITORIO_CONFIG ?? join(homedir(), '.config/escritorio');
const archivo = join(carpeta, 'config.json');
const leido: { pendientes?: string; notas?: string; ideas?: string; baul?: string } = existsSync(archivo)
  ? JSON.parse(readFileSync(archivo, 'utf8'))
  : {};

const expandir = (ruta: string) => ruta.replace(/^~(?=\/|$)/, homedir());

const pendientes = expandir(process.env.ESCRITORIO_PENDIENTES ?? leido.pendientes ?? '~/Documents/Pendientes.md');

export const config = {
  pendientes,
  notas: expandir(leido.notas ?? dirname(pendientes)),
  ideas: expandir(leido.ideas ?? '~/.local/state/baul-memoria/ideas.json'),
  baul: expandir(leido.baul ?? '~/Documents/Proyectos Michi/baul-mcp'),
  // Direcciones secretas iCal, una por línea ("Nombre | https://…"): dan acceso al calendario.
  calendarios: process.env.ESCRITORIO_CALENDARIOS ?? join(carpeta, 'calendarios.txt'),
  cache: join(homedir(), '.cache/escritorio'),
};
