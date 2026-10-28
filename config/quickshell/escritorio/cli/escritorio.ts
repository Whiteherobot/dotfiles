// Datos de los widgets del escritorio. Salida JSON para Quickshell (y para scripts).
//   escritorio estado                          → pendientes sin terminar y todos, para el tablero
//   escritorio tarea agregar "texto" [--en-curso] [--nota "Nota"]
//   escritorio tarea <indice> <pendiente|en-curso|hecha> [--texto "texto esperado"]
//   escritorio tarea lista
//   escritorio tarea detalle <indice>          → avance de la nota vinculada (null si no tiene)
//   escritorio calendario [--desde F] [--hasta F] [--forzar] → eventos por día (iCal)
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { parseArgs } from 'node:util';
import { consultarCalendario, rangoPorDefecto } from './calendario.ts';
import { config } from './config.ts';
import { hoyLocal } from './fechas.ts';
import { detalleDeNota } from './notas.ts';
import { guardarEstadoTarea, guardarNuevaTarea, leerTareas, type EstadoTarea } from './tareas.ts';

const imprimir = (x: unknown) => console.log(JSON.stringify(x, null, 2));

const { positionals, values } = parseArgs({
  allowPositionals: true,
  options: {
    nota: { type: 'string' },
    'en-curso': { type: 'boolean' },
    texto: { type: 'string' },
    desde: { type: 'string' },
    hasta: { type: 'string' },
    forzar: { type: 'boolean' },
  },
});
const [comando, ...args] = positionals;

switch (comando) {
  case 'estado': {
    const todas = leerTareas(config.pendientes);
    imprimir({
      hoy: hoyLocal(),
      archivo: config.pendientes,
      // Sin terminar; primero lo que está en curso.
      tareas: todas
        .filter((t) => t.estado !== 'hecha')
        .sort((a, b) => Number(b.estado === 'en-curso') - Number(a.estado === 'en-curso') || a.indice - b.indice),
      // Todas, en el orden del archivo, para el tablero kanban.
      todasLasTareas: todas,
    });
    break;
  }
  case 'tarea': {
    const [accion, arg] = args;
    if (accion === 'agregar') {
      mkdirSync(dirname(config.pendientes), { recursive: true });
      guardarNuevaTarea(config.pendientes, args.slice(1).join(' '), values['en-curso'] ? 'en-curso' : 'pendiente', values.nota);
    } else if (accion === 'detalle') {
      const tarea = leerTareas(config.pendientes).find((t) => t.indice === Number(arg));
      imprimir(tarea?.nota ? (detalleDeNota(config.notas, tarea.nota) ?? null) : null);
      break;
    } else if (accion !== 'lista') {
      if (!['pendiente', 'en-curso', 'hecha'].includes(arg)) throw new Error(`Estado inválido: ${arg}`);
      guardarEstadoTarea(config.pendientes, Number(accion), arg as EstadoTarea, values.texto);
    }
    imprimir(leerTareas(config.pendientes));
    break;
  }
  case 'calendario': {
    const [desde, hasta] = rangoPorDefecto(hoyLocal());
    imprimir(await consultarCalendario(values.desde ?? desde, values.hasta ?? hasta, values.forzar));
    break;
  }
  default:
    console.error('Uso: escritorio estado | tarea … | calendario [--desde F] [--hasta F] [--forzar]');
    process.exit(1);
}
