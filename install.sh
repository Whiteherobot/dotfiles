#!/usr/bin/env bash
# Enlaza los archivos del repo en su lugar. Lo que ya exista se mueve a
# ~/.dotfiles-respaldo/<fecha>/ antes de reemplazarlo.
#   ./install.sh            instala la configuración de 2025 (Arch + Hyprland)
#   ./install.sh --omarchy  instala la configuración actual (Omarchy, 2026)
#   --prueba                muestra lo que haría sin tocar nada (combinable)
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
respaldo="$HOME/.dotfiles-respaldo/$(date +%Y%m%d-%H%M%S)"
prueba=false
omarchy=false
for arg in "$@"; do
  case "$arg" in
    --prueba) prueba=true ;;
    --omarchy) omarchy=true ;;
    *) echo "opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

corto() { echo "~${1#"$HOME"}"; }

enlaces=(
  "hypr/hyprland.conf:.config/hypr/hyprland.conf"
  "waybar/config:.config/waybar/config"
  "waybar/style.css:.config/waybar/style.css"
  "zsh/.zshrc:.zshrc"
)

# Omarchy trae sus valores por defecto en ~/.local/share/omarchy; estos son solo mis cambios.
if $omarchy; then
  enlaces=()
  for f in hyprland.lua bindings.lua monitors.lua looknfeel.lua input.lua autostart.lua \
           hypridle.conf hyprlock.conf hyprsunset.conf input.conf xdph.conf; do
    enlaces+=("omarchy/hypr/$f:.config/hypr/$f")
  done
  enlaces+=(
    "omarchy/waybar/config.jsonc:.config/waybar/config.jsonc"
    "omarchy/waybar/style.css:.config/waybar/style.css"
    "omarchy/waybar/scripts/jarvis-indicator.sh:.config/waybar/scripts/jarvis-indicator.sh"
    "omarchy/starship.toml:.config/starship.toml"
  )
fi

for par in "${enlaces[@]}"; do
  origen="$repo/${par%%:*}"
  destino="$HOME/${par#*:}"

  if [[ -L "$destino" && "$(readlink "$destino")" == "$origen" ]]; then
    echo "ya enlazado  $(corto "$destino")"
    continue
  fi
  if $prueba; then
    [[ -e "$destino" || -L "$destino" ]] && echo "respaldaría  $(corto "$destino")"
    echo "enlazaría    $(corto "$destino")"
    continue
  fi
  if [[ -e "$destino" || -L "$destino" ]]; then
    mkdir -p "$respaldo/$(dirname "${par#*:}")"
    mv "$destino" "$respaldo/${par#*:}"
    echo "respaldado   $(corto "$destino")"
  fi
  mkdir -p "$(dirname "$destino")"
  ln -s "$origen" "$destino"
  echo "enlazado     $(corto "$destino")"
done
