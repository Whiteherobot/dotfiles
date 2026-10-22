#!/bin/bash
# "Ahora suena" para la Waybar: título y artista del reproductor activo (Apple Music,
# Spotify, YouTube…) vía MPRIS. Sin nada sonando, el módulo queda vacío y se oculta.

# Al reiniciar la Waybar se cierra este script: llevarse también a los procesos hijos.
# El pipeline va en segundo plano con wait, porque bash no corre el trap mientras espera
# un pipeline en primer plano.
trap 'pkill -P $$ 2>/dev/null' EXIT TERM HUP INT

emit() {
  local status="$1" artist="$2" title="$3"
  if [[ -z $title || $status == "Stopped" ]]; then
    echo '{"text": "", "class": "stopped"}'
    return
  fi
  local icon="󰎆"; [[ $status == "Paused" ]] && icon="󰏤"
  local label="$title"; [[ -n $artist ]] && label="$title — $artist"
  local short="$label"; (( ${#short} > 32 )) && short="${short:0:31}…"
  jq -cn --arg t "$icon  $short" --arg tip "$label" --arg c "${status,,}" '{text: $t, tooltip: $tip, class: $c}'
}

emit "" "" ""
playerctl --follow metadata --format $'{{status}}\t{{artist}}\t{{title}}' 2>/dev/null |
  while IFS=$'\t' read -r status artist title; do emit "$status" "$artist" "$title"; done &
wait
