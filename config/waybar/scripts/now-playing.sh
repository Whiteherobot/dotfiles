#!/bin/bash
# "Ahora suena" para la Waybar: título y artista del reproductor activo (Apple Music,
# Spotify, YouTube…) vía MPRIS. Sin nada sonando, el módulo queda vacío y se oculta.

# Al reiniciar la Waybar se cierra este script: llevarse también a los procesos hijos.
# El bucle va en segundo plano con wait, porque bash no corre el trap mientras espera
# un proceso en primer plano.
trap 'pkill -P $$ 2>/dev/null' EXIT TERM HUP INT

pango_escape() {
  local s="$1"
  s=${s//&/\&amp;}; s=${s//</\&lt;}; s=${s//>/\&gt;}
  printf '%s' "$s"
}

emit() {
  local status="$1" artist="$2" title="$3"
  if [[ -z $title || $status == "Stopped" ]]; then
    echo '{"text": "", "class": "stopped"}'
    return
  fi
  local icon="󰎆"; [[ $status == "Paused" ]] && icon="󰏤"
  local label="$title"; [[ -n $artist ]] && label="$title — $artist"
  local short="$label"; (( ${#short} > 32 )) && short="${short:0:31}…"
  # La Waybar interpreta el texto como marcado Pango: un "&" suelto (p. ej. "Ima & muque") lo vacía.
  # Se escapa después de recortar para no partir una entidad; el "&" del reemplazo va con "\".
  short=$(pango_escape "$short"); label=$(pango_escape "$label")
  jq -cn --arg t "$icon  $short" --arg tip "$label" --arg c "${status,,}" '{text: $t, tooltip: $tip, class: $c}'
}

# Se consulta cada segundo en vez de "playerctl --follow": el follow se quedaba trabado
# horas después de arrancar (sobre todo al aparecer playerctld) y el título no cambiaba.
# Separador \x1f: con tabuladores bash junta los campos vacíos (pista sin artista).
poll() {
  local last="init" now
  while :; do
    now=$(playerctl metadata --format $'{{status}}\x1f{{artist}}\x1f{{title}}' 2>/dev/null)
    if [[ $now != "$last" ]]; then
      IFS=$'\x1f' read -r status artist title <<< "$now"
      emit "$status" "$artist" "$title"
      last=$now
    fi
    sleep 1
  done
}

poll &
wait
