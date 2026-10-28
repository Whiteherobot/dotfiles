import assert from 'node:assert/strict';
import { test } from 'node:test';
import { limpiar, resumirNota } from '../cli/notas.ts';

test('notas: limpia wikilinks con alias y encabezado', () => {
  assert.equal(limpiar('ver [[A|el a]] y [[B#Sec]] y [[C]]'), 'ver el a y B y C');
});

test('notas: resume aviso, checklist y secciones de avance', () => {
  const md = [
    '# P',
    '> [!success] Estado: ENTREGADA',
    '> Repo [[X|público]].',
    '',
    '## Contexto',
    'algo',
    '## Pendiente',
    '- [x] uno',
    '- [ ] dos',
    '## Historial',
    ...Array.from({ length: 9 }, (_, i) => `- paso ${i}`),
    '## Relacionado',
    '- [[Z]]',
  ].join('\n');
  const r = resumirNota(md);
  assert.deepEqual(r.aviso, { tipo: 'success', texto: 'Estado: ENTREGADA\nRepo público.' });
  assert.deepEqual(r.checklist, { hechos: 1, total: 2, siguientes: ['dos'] });
  assert.deepEqual(r.secciones.map((s) => s.titulo), ['Pendiente', 'Historial']);
  assert.match(r.secciones[1].texto, /^…\n- paso 3/);
});

test('notas: sin secciones de avance usa la primera', () => {
  assert.deepEqual(resumirNota('# P\n## Idea\nhola\n## Otra\nx').secciones, [{ titulo: 'Idea', texto: 'hola' }]);
});
