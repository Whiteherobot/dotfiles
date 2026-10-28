// Fechas como "YYYY-MM-DD" en hora local. Se opera en UTC sobre esas partes
// para que los cambios de horario no muevan días.

export const DIAS = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'] as const;
export type DiaSemana = (typeof DIAS)[number];

const aUtc = (fecha: string): number => {
  const [a, m, d] = fecha.split('-').map(Number);
  return Date.UTC(a, m - 1, d);
};

const desdeUtc = (ms: number): string => new Date(ms).toISOString().slice(0, 10);

export const hoyLocal = (ahora = new Date()): string => {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${ahora.getFullYear()}-${p(ahora.getMonth() + 1)}-${p(ahora.getDate())}`;
};

export const sumarDias = (fecha: string, n: number): string => desdeUtc(aUtc(fecha) + n * 86_400_000);

export const diferenciaDias = (desde: string, hasta: string): number =>
  Math.round((aUtc(hasta) - aUtc(desde)) / 86_400_000);

export const diaSemana = (fecha: string): DiaSemana => DIAS[new Date(aUtc(fecha)).getUTCDay()];
