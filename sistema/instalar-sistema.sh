#!/usr/bin/env bash
# Copia los arreglos de sistema de la ASUS ROG Strix G16 (G614JV) a /etc.
# Muestra la diferencia de cada archivo y pide confirmación uno por uno.
# Uso: sudo ./sistema/instalar-sistema.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Correr con sudo: sudo $0" >&2
  exit 1
fi

aqui="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usuario="${SUDO_USER:-$USER}"
cambio_initramfs=false

while IFS= read -r -d '' origen; do
  destino="/${origen#"$aqui"/}"
  temporal="$(mktemp)"
  # El autologin lleva el usuario de quien instala
  sed "s/^User=.*/User=$usuario/" "$origen" > "$temporal"
  if [[ -f $destino ]] && cmp -s "$temporal" "$destino"; then
    echo "igual        $destino"
    rm -f "$temporal"
    continue
  fi
  echo
  echo "── $destino"
  if [[ -f $destino ]]; then diff -u "$destino" "$temporal" || true; else cat "$temporal"; fi
  read -r -p "¿Instalar este archivo? [s/N] " r
  if [[ $r =~ ^[sS]$ ]]; then
    [[ -f $destino ]] && cp -a "$destino" "$destino.bak.$(date +%s)"
    install -Dm644 "$temporal" "$destino"
    echo "instalado    $destino"
    [[ $destino == /etc/mkinitcpio.conf.d/* ]] && cambio_initramfs=true
  fi
  rm -f "$temporal"
done < <(find "$aqui/etc" -type f -print0 | sort -z)

# La VRAM de NVIDIA se guarda al suspender/hibernar solo si estos servicios están activos
systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null || true

if $cambio_initramfs; then
  read -r -p "Cambió el initramfs. ¿Regenerarlo ahora (mkinitcpio -P)? [s/N] " r
  [[ $r =~ ^[sS]$ ]] && mkinitcpio -P
fi
echo "Listo. Reiniciar para aplicar los cambios de NVIDIA y del login."
