import { existsSync, readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { spawnSync } from 'node:child_process';
import { config } from './config.ts';

export interface Idea {
  id: string;
  etiqueta: string;
  texto: string;
  proyecto: string;
}

export const leerIdeas = (ruta: string): Idea[] => {
  if (!existsSync(ruta)) return [];
  try {
    const leido: unknown = JSON.parse(readFileSync(ruta, 'utf8'));
    const candidatas = Array.isArray(leido) ? leido : leido && typeof leido === 'object' && Array.isArray((leido as { ideas?: unknown }).ideas)
      ? (leido as { ideas: unknown[] }).ideas
      : [];
    return candidatas.slice(0, 3).map((idea) => {
      const dato = idea as { id: string; etiqueta: string; resumen?: string; texto?: string; proyecto: string };
      return {
        id: dato.id,
        etiqueta: dato.etiqueta.replace(/^\[\[|\]\]$/g, ''),
        texto: dato.resumen ?? dato.texto ?? '',
        proyecto: basename(dato.proyecto).replace(/\.md$/, ''),
      };
    });
  } catch {
    return [];
  }
};

export const decidirIdea = (id: string, si: boolean): unknown => {
  const resultado = spawnSync(
    `${config.baul}/.venv/bin/python`,
    [`${config.baul}/proponer.py`, 'decidir', id, si ? 'si' : 'no'],
    { cwd: config.baul, encoding: 'utf8' },
  );
  if (resultado.status !== 0) throw new Error(resultado.stderr);
  return JSON.parse(resultado.stdout);
};
