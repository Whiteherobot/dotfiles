# ~/.zshrc - configuración inicial

# Variables de entorno
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
export VISUAL=code

# Aliases útiles
alias ll='ls -lah --color=auto'
alias gs='git status'
alias gp='git pull'
alias gcm='git commit -m'

# Copilot CLI
alias copilot='code --install-extension GitHub.copilot'

# NVIDIA GPU Environment (Wayland / Hyprland)
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Prompt Starship para Zsh
eval "$(starship init zsh)"

# Detectar si la shell fue lanzada directamente por kitty (nueva ventana física)
PARENT_PROC=$(ps -p $PPID -o comm=)

if [[ -z "$TMUX" ]] && [[ -z "$SSH_TTY" ]] && [[ "$PARENT_PROC" == "kitty" ]]; then
  fastfetch 
fi

# === Historial persistente ===
HISTFILE=~/.zsh_history   # Archivo donde se guarda el historial
HISTSIZE=10000            # Número de comandos a guardar en RAM
SAVEHIST=10000            # Número de comandos a guardar en disco

setopt APPEND_HISTORY     # Agregar, no sobrescribir
setopt INC_APPEND_HISTORY # Guardar comandos inmediatamente
setopt SHARE_HISTORY      # Compartir entre sesiones Zsh abiertas
setopt HIST_IGNORE_DUPS   # Ignorar duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS  # Ignorar duplicados en todo el archivo
setopt HIST_REDUCE_BLANKS    # Quitar espacios innecesarios
# === Flechas arriba/abajo ===
bindkey "^[[A" up-line-or-history
bindkey "^[[B" down-line-or-history

# === Buscar comandos que comienzan igual ===
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
