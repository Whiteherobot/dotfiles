import assert from 'node:assert/strict';
import { test } from 'node:test';
import { eventosPorDia, leerCalendarios, parsearIcs, rangoPorDefecto } from '../cli/calendario.ts';

// Las pruebas corren con TZ=America/Guayaquil (UTC-5, sin horario de verano): ver el script "test".
const ics = (...eventos: string[]) =>
  ['BEGIN:VCALENDAR', 'VERSION:2.0', ...eventos.flatMap((e) => ['BEGIN:VEVENT', ...e.split('\n'), 'END:VEVENT']), 'END:VCALENDAR'].join('\r\n');

test('calendario: evento con hora en UTC pasa a hora local', () => {
  const d = eventosPorDia(parsearIcs(ics('UID:a\nSUMMARY:Clase\\, aula 3\nDTSTART:20261023T150000Z\nDTEND:20261023T163000Z')), '2026-10-01', '2026-10-31');
  assert.deepEqual(d['2026-10-23'], [{ inicio: '10:00', fin: '11:30', titulo: 'Clase, aula 3', lugar: '', todoElDia: false, calendario: 0 }]);
});

test('calendario: TZID de otra zona y líneas plegadas', () => {
  const d = eventosPorDia(parsearIcs(ics('UID:b\nSUMMARY:Reunión con\n  Madrid\nDTSTART;TZID=Europe/Madrid:20261023T170000\nDTEND;TZID=Europe/Madrid:20261023T180000')), '2026-10-01', '2026-10-31');
  assert.equal(d['2026-10-23'][0].titulo, 'Reunión con Madrid');
  assert.equal(d['2026-10-23'][0].inicio, '10:00'); // Madrid en octubre = UTC+2
});

test('calendario: día completo de varios días aparece en cada día', () => {
  const d = eventosPorDia(parsearIcs(ics('UID:c\nSUMMARY:Feriado\nDTSTART;VALUE=DATE:20261102\nDTEND;VALUE=DATE:20261104')), '2026-11-01', '2026-11-30');
  assert.deepEqual(Object.keys(d).sort(), ['2026-11-02', '2026-11-03']);
  assert.equal(d['2026-11-02'][0].todoElDia, true);
});

test('calendario: semanal con BYDAY, UNTIL, EXDATE y una ocurrencia movida', () => {
  const eventos = parsearIcs(ics(
    `UID:r\nSUMMARY:Paralela\nDTSTART;TZID=America/Guayaquil:20261005T070000\nDTEND;TZID=America/Guayaquil:20261005T090000\nRRULE:FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20261021T235959Z\nEXDATE;TZID=America/Guayaquil:20261012T070000`,
    'UID:r\nSUMMARY:Paralela (movida)\nRECURRENCE-ID;TZID=America/Guayaquil:20261014T070000\nDTSTART;TZID=America/Guayaquil:20261015T070000\nDTEND;TZID=America/Guayaquil:20261015T090000',
  ));
  const d = eventosPorDia(eventos, '2026-10-01', '2026-10-31');
  assert.deepEqual(Object.keys(d).sort(), ['2026-10-05', '2026-10-07', '2026-10-15', '2026-10-19', '2026-10-21']);
  assert.equal(d['2026-10-15'][0].titulo, 'Paralela (movida)');
});

test('calendario: mensual por ordinal, COUNT y cancelados', () => {
  const d = eventosPorDia(parsearIcs(ics(
    'UID:m\nSUMMARY:Pago\nDTSTART;VALUE=DATE:20260130\nRRULE:FREQ=MONTHLY;BYDAY=-1FR;COUNT=3',
    'UID:x\nSUMMARY:Cancelado\nSTATUS:CANCELLED\nDTSTART:20260210T150000Z',
  )), '2026-01-01', '2026-06-30');
  assert.deepEqual(Object.keys(d).sort(), ['2026-01-30', '2026-02-27', '2026-03-27']);
});

test('calendario: ignora alarmas anidadas y lee la lista de calendarios', () => {
  const e = parsearIcs(ics('UID:z\nSUMMARY:Con alarma\nDTSTART:20261023T150000Z\nBEGIN:VALARM\nSUMMARY:no soy el título\nEND:VALARM'));
  assert.equal(e[0].titulo, 'Con alarma');
  assert.deepEqual(leerCalendarios('# comentario\nPersonal | webcal://x/a.ics\nhttps://x/b.ics\n'), [
    { nombre: 'Personal', url: 'https://x/a.ics' },
    { nombre: 'Calendario 2', url: 'https://x/b.ics' },
  ]);
});

test('calendario: el rango cubre la cuadrícula del mes y dos semanas adelante', () => {
  assert.deepEqual(rangoPorDefecto('2026-10-23'), ['2026-09-28', '2026-11-08']);
  assert.deepEqual(rangoPorDefecto('2026-10-30'), ['2026-09-28', '2026-11-13']);
});
