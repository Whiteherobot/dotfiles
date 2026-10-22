#!/bin/bash
# Barras tipo ecualizador para la Waybar a partir de cava. En silencio no muestra nada.

# Al reiniciar la Waybar se cierra este script: llevarse también a los procesos hijos.
# El pipeline va en segundo plano con wait, porque bash no corre el trap mientras espera
# un pipeline en primer plano.
trap 'pkill -P $$ 2>/dev/null' EXIT TERM HUP INT
BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
cava -p ~/.config/cava/waybar.conf 2>/dev/null | while IFS=';' read -ra levels; do
  line=""; total=0
  for v in "${levels[@]}"; do [[ $v =~ ^[0-7]$ ]] || continue; line+="${BARS[$v]}"; total=$((total + v)); done
  (( total == 0 )) && line=""
  echo "$line"
done &
wait
