#!/usr/bin/env bash
# Enlaza los archivos del repo en su lugar. Lo que ya exista se mueve a
# ~/.dotfiles-respaldo/<fecha>/ antes de reemplazarlo.
#   ./install.sh          instala
#   ./install.sh --prueba muestra lo que haría sin tocar nada
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
respaldo="$HOME/.dotfiles-respaldo/$(date +%Y%m%d-%H%M%S)"
prueba=false
[[ "${1:-}" == "--prueba" ]] && prueba=true

corto() { echo "~${1#"$HOME"}"; }

enlaces=(
  "hypr/hyprland.conf:.config/hypr/hyprland.conf"
  "waybar/config:.config/waybar/config"
  "waybar/style.css:.config/waybar/style.css"
  "zsh/.zshrc:.zshrc"
)

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
