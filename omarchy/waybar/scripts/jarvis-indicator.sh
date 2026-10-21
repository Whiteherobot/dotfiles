#!/bin/bash
# Indicador de estado de jarvis-voz (wake word + STT + Claude + TTS).
# Estados: idle (oculto), listening, thinking, speaking.

STATE_FILE="$HOME/.cache/jarvis-voz/state.json"
STALE_SECONDS=30

if ! systemctl --user is-active --quiet jarvis-voz.service; then
  echo '{"text": "", "tooltip": "Jarvis (voz): servicio detenido"}'
  exit 0
fi

if [[ ! -f "$STATE_FILE" ]]; then
  echo '{"text": "", "tooltip": "Jarvis (voz): activo"}'
  exit 0
fi

age=$(( $(date +%s) - $(date -r "$STATE_FILE" +%s) ))
state=$(jq -r '.state' "$STATE_FILE" 2>/dev/null)
detail=$(jq -r '.detail' "$STATE_FILE" 2>/dev/null)

if (( age > STALE_SECONDS )) && [[ "$state" != "idle" ]]; then
  echo '{"text": "", "tooltip": "Jarvis (voz): activo"}'
  exit 0
fi

case "$state" in
  listening)
    echo "{\"text\": \"󰍬\", \"class\": \"listening\", \"tooltip\": \"Jarvis: escuchando...\"}"
    ;;
  thinking)
    echo "{\"text\": \"󰦖\", \"class\": \"thinking\", \"tooltip\": \"Jarvis pensando: ${detail//\"/\\\"}\"}"
    ;;
  speaking)
    echo "{\"text\": \"󰕾\", \"class\": \"speaking\", \"tooltip\": \"Jarvis responde: ${detail//\"/\\\"}\"}"
    ;;
  *)
    echo '{"text": "", "tooltip": "Jarvis (voz): activo"}'
    ;;
esac
