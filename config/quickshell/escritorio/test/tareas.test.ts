import assert from 'node:assert/strict';
import { test } from 'node:test';
import { agregarTarea, cambiarEstado, parsearTareas } from '../cli/tareas.ts';

test('tareas: crea el archivo con cabecera y agrega al final', () => {
  const md = agregarTarea(agregarTarea('', 'Informe de Paralela'), 'Revisar CredyNox', 'en-curso');
  assert.match(md, /^# Pendientes\n/);
  assert.match(md, /\n\n- \[ \] Informe de Paralela\n- \[\/\] Revisar CredyNox\n$/);
  assert.deepEqual(parsearTareas(md), [
    { indice: 0, texto: 'Informe de Paralela', estado: 'pendiente' },
    { indice: 1, texto: 'Revisar CredyNox', estado: 'en-curso' },
  ]);
});

test('tareas: respeta el resto de la nota editada en Obsidian', () => {
  const md = '# Pendientes\n\nnotas sueltas\n- [x] vieja\n- [ ] nueva\n\n## Ideas\n- sin casilla\n';
  const r = cambiarEstado(md, 1, 'en-curso', 'nueva');
  assert.equal(r, md.replace('- [ ] nueva', '- [/] nueva'));
  assert.equal(parsearTareas(md).length, 2);
});

test('tareas: no marca otra tarea si la lista cambió', () => {
  const md = agregarTarea('', 'a');
  assert.throws(() => cambiarEstado(md, 0, 'hecha', 'b'), /La lista cambió/);
  assert.throws(() => cambiarEstado(md, 3, 'hecha'), /No existe/);
  assert.throws(() => agregarTarea(md, '   '), /vacía/);
});

test('tareas: separa la nota vinculada y la conserva al marcar', () => {
  const md = agregarTarea('', 'Estéreo: mediciones', 'pendiente', 'Checklist Estéreo');
  assert.match(md, /- \[ \] Estéreo: mediciones \[\[Checklist Estéreo\]\]\n$/);
  assert.deepEqual(parsearTareas('- [ ] a [[Nota|alias]]\n'), [{ indice: 0, texto: 'a', estado: 'pendiente', nota: 'Nota' }]);
  const r = cambiarEstado(md, 0, 'hecha', 'Estéreo: mediciones');
  assert.match(r, /- \[x\] Estéreo: mediciones \[\[Checklist Estéreo\]\]/);
});
