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
for f in "$repo"/config/cava/*; do enlaces+=("config/cava/${f##*/}:.config/cava/${f##*/}"); done
for f in "$repo"/config/systemd/user/*; do enlaces+=("config/systemd/user/${f##*/}:.config/systemd/user/${f##*/}"); done
for f in "$repo"/config/omarchy/themed/*; do enlaces+=("config/omarchy/themed/${f##*/}:.config/omarchy/themed/${f##*/}"); done
for f in "$repo"/bin/*; do enlaces+=("bin/${f##*/}:.local/bin/${f##*/}"); done
enlaces+=(
  "config/uwsm/env.d/99-omarchy-upgrade-env:.config/uwsm/env.d/99-omarchy-upgrade-env"
  "config/omarchy/bar/modules/visualizer.qml:.config/omarchy/bar/modules/visualizer.qml"
  "config/starship.toml:.config/starship.toml"
  "config/omarchy/branding/caja-retro/hanko-boot.png:.config/omarchy/branding/caja-retro/hanko-boot.png"
  "config/fastfetch/config.jsonc:.config/fastfetch/config.jsonc"
  "config/fastfetch/img/logo.sixel:.config/fastfetch/img/logo.sixel"
  "config/fastfetch/img/logo.png:.config/fastfetch/img/logo.png"
  "config/quickshell/escritorio:.config/quickshell/escritorio"
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

# Caja Retro: gruvbox con bordes crema. Los fondos son de wallhaven.cc y tampoco se
# redistribuyen; el nombre lleva el id (01-8xv35o.jpg → https://wallhaven.cc/w/8xv35o).
tema="$HOME/.config/omarchy/themes/caja-retro"
fondos=(01-8xv35o.jpg 02-132m93.jpg 03-1k6ljv.jpg 04-1p6d79.jpg 05-x6pl9v.jpg
        06-y8q2g7.jpg 07-ymz61d.jpg 08-wq37kp.jpg 09-5779j8.jpg 10-nr7v8w.png)
if $prueba; then
  echo "copiaría     $(corto "$tema") y descargaría los fondos que falten"
else
  mkdir -p "$tema/backgrounds"
  cp "$repo"/config/omarchy/themes/caja-retro/* "$tema/"
  for f in "${fondos[@]}"; do
    id="${f#*-}"; id="${id%.*}"
    if [[ -s $tema/backgrounds/$f ]] || ! hay curl; then continue; fi
    curl -fsSL -o "$tema/backgrounds/$f" "https://w.wallhaven.cc/full/${id:0:2}/wallhaven-$id.${f##*.}" ||
      echo "aviso: no se pudo bajar el fondo $f"
  done
  echo "tema         $(corto "$tema")"
fi

# La barra (shell.json), el panel de agentes y los escritorios con kanji se copian: Omarchy reescribe shell.json con
# "omarchy bar …" y un enlace se perdería. Lo que ya exista se respalda igual que arriba.
copias=(
  "config/omarchy/shell.json:.config/omarchy/shell.json"
  "config/omarchy/plugins/ing_michi.agents:.config/omarchy/plugins/ing_michi.agents"
  "config/omarchy/plugins/ing_michi.workspaces:.config/omarchy/plugins/ing_michi.workspaces"
)
for par in "${copias[@]}"; do
  origen="$repo/${par%%:*}"
  destino="$HOME/${par#*:}"
  if diff -rq "$origen" "$destino" >/dev/null 2>&1; then
    echo "ya copiado   $(corto "$destino")"
    continue
  fi
  if $prueba; then
    echo "copiaría     $(corto "$destino")"
    continue
  fi
  if [[ -e $destino || -L $destino ]]; then
    mkdir -p "$respaldo/$(dirname "${par#*:}")"
    mv "$destino" "$respaldo/${par#*:}"
  fi
  mkdir -p "$(dirname "$destino")"
  cp -a "$origen" "$destino"
  echo "copiado      $(corto "$destino")"
done

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
  # Enchufado = pantalla despierta; aviso de actualizaciones cada 7 días como mínimo
  systemctl --user enable ac-stay-awake.service actualizaciones-aviso.timer >/dev/null 2>&1 || true
  # Uso de Copilot y Gemini (agy) en el panel de agentes, solo si están instalados
  if hay copilot; then systemctl --user enable --now omarchy-agent-usage-copilot.timer >/dev/null 2>&1 || true; fi
  if hay agy; then systemctl --user enable --now omarchy-agent-usage-antigravity.timer >/dev/null 2>&1 || true; fi
fi

# LLM local (opcional): Ollama + Open WebUI ("Faro") + SearXNG; se prende con el cargador.
# Las claves se generan aquí y no se pisan si ya existen.
faro_datos="$HOME/.local/share/faro"
if ! $prueba && hay ollama && hay docker && hay systemctl; then
  clave() { od -An -N32 -tx1 /dev/urandom | tr -d ' \n'; }
  mkdir -p "$faro_datos/searxng" "$HOME/.local/share/icons/hicolor/scalable/apps"
  cp "$repo/config/faro/faro.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/"
  if [[ ! -s $faro_datos/secreto.env ]]; then
    (umask 077; echo "WEBUI_SECRET_KEY=$(clave)" > "$faro_datos/secreto.env")
  fi
  if [[ ! -e $faro_datos/searxng/settings.yml ]]; then
    sed "s/se-genera-al-instalar/$(clave)/" "$repo/config/faro/searxng/settings.yml" > "$faro_datos/searxng/settings.yml"
  fi
  systemctl --user enable llm-cargador.service >/dev/null 2>&1 && echo "servicio     llm-cargador (LLM local con el cargador)"
  systemctl --user enable --now omarchy-agent-usage-faro.timer >/dev/null 2>&1 || true
  [[ -d $HOME/.ollama/models/manifests/registry.ollama.ai/library/faro ]] ||
    echo "aviso: falta el modelo: ollama pull qwen3.5:9b && ollama create faro -f $repo/config/faro/Modelfile"
elif ! $prueba; then
  echo "aviso: sin ollama o docker; el LLM local (Super+I) queda sin activar"
fi

if [[ -d $respaldo ]]; then echo "respaldo en  $(corto "$respaldo")"; fi
if ! $prueba; then
  cat <<'EOF'

Listo. Para terminar:
  omarchy theme set "Caja Retro"     # tema y colores (o Aether)
  omarchy restart shell               # barra con música y panel de agentes
  sudo ./sistema/instalar-sistema.sh  # arreglos de la laptop (NVIDIA, hibernación, login)
EOF
fi
