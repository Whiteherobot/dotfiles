#!/usr/bin/env bash
# Instala la configuración de usuario (Omarchy sobre CachyOS, ASUS ROG Strix G16 G614JV).
# Enlaza cada archivo del repo en su lugar; lo que ya exista se mueve antes a
# ~/.dotfiles-respaldo/<fecha>/. Los arreglos de sistema (/etc) van aparte:
# sudo ./sistema/instalar-sistema.sh
#   ./install.sh            instala
#   ./install.sh --prueba   muestra lo que haría sin tocar nada
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
respaldo="$HOME/.dotfiles-respaldo/$(date +%Y%m%d-%H%M%S)"
prueba=false
for arg in "$@"; do
  case "$arg" in
    --prueba) prueba=true ;;
    *) echo "opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

corto() { echo "~${1#"$HOME"}"; }
hay() { command -v "$1" >/dev/null 2>&1; }

# origen en el repo : destino relativo a $HOME
enlaces=()
for f in "$repo"/config/hypr/*; do enlaces+=("config/hypr/${f##*/}:.config/hypr/${f##*/}"); done
for f in "$repo"/config/waybar/scripts/*; do enlaces+=("config/waybar/scripts/${f##*/}:.config/waybar/scripts/${f##*/}"); done
for f in "$repo"/config/cava/*; do enlaces+=("config/cava/${f##*/}:.config/cava/${f##*/}"); done
for f in "$repo"/config/systemd/user/*; do enlaces+=("config/systemd/user/${f##*/}:.config/systemd/user/${f##*/}"); done
for f in "$repo"/config/omarchy/themed/*; do enlaces+=("config/omarchy/themed/${f##*/}:.config/omarchy/themed/${f##*/}"); done
for f in "$repo"/bin/*; do enlaces+=("bin/${f##*/}:.local/bin/${f##*/}"); done
enlaces+=(
  "config/waybar/config.jsonc:.config/waybar/config.jsonc"
  "config/waybar/style.css:.config/waybar/style.css"
  "config/uwsm/env:.config/uwsm/env"
  "config/starship.toml:.config/starship.toml"
)

for par in "${enlaces[@]}"; do
  origen="$repo/${par%%:*}"
  destino="$HOME/${par#*:}"
  if [[ -L $destino && "$(readlink "$destino")" == "$origen" ]]; then
    echo "ya enlazado  $(corto "$destino")"
    continue
  fi
  if $prueba; then
    echo "enlazaría    $(corto "$destino")"
    continue
  fi
  if [[ -e $destino || -L $destino ]]; then
    mkdir -p "$respaldo/$(dirname "${par#*:}")"
    mv "$destino" "$respaldo/${par#*:}"
  fi
  mkdir -p "$(dirname "$destino")"
  ln -s "$origen" "$destino"
  echo "enlazado     $(corto "$destino")"
done

# El tema tiene que ser una carpeta real (Omarchy no sigue enlaces en themes/).
tema="$HOME/.config/omarchy/themes/aether"
fondo="$tema/backgrounds/wallhaven-xekydd.jpg"
if $prueba; then
  echo "copiaría     $(corto "$tema") y descargaría el fondo si falta"
else
  mkdir -p "$tema/backgrounds"
  cp "$repo"/config/omarchy/themes/aether/* "$tema/"
  if [[ ! -s $fondo ]] && hay curl; then
    # Fondo de wallhaven.cc (no se redistribuye en el repo): https://wallhaven.cc/w/xekydd
    curl -fsSL -o "$fondo" https://w.wallhaven.cc/full/xe/wallhaven-xekydd.jpg || echo "aviso: no se pudo bajar el fondo"
  fi
  echo "tema         $(corto "$tema")"
fi

# Apple Music como app web, igual que las que trae Omarchy (WhatsApp, Discord…)
if ! $prueba && hay omarchy && [[ ! -e "$HOME/.local/share/applications/Apple Music.desktop" ]]; then
  omarchy webapp install "Apple Music" "https://music.apple.com/" \
    "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/apple-music.png"
  echo "app web      Apple Music"
fi

if ! $prueba && hay systemctl; then
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable omarchy-recover-internal-monitor.service >/dev/null 2>&1 || true
  if hay asusctl && hay cava; then
    systemctl --user enable --now kbd-music.service >/dev/null 2>&1 && echo "servicio     kbd-music (teclado reactivo a la música)"
  else
    echo "aviso: falta asusctl o cava; el teclado reactivo queda sin activar (omarchy pkg add cava)"
  fi
fi

if [[ -d $respaldo ]]; then echo "respaldo en  $(corto "$respaldo")"; fi
if ! $prueba; then
  cat <<'EOF'

Listo. Para terminar:
  omarchy theme set Aether            # tema y colores
  omarchy restart waybar              # barra con música
  sudo ./sistema/instalar-sistema.sh  # arreglos de la laptop (NVIDIA, hibernación, login)
EOF
fi
