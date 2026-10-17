# ~/.zshrc

# Variables de entorno
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
export VISUAL=code

# Aliases
alias ll='ls -lah --color=auto'
alias gs='git status'
alias gp='git pull'
alias gcm='git commit -m'

# Prompt Starship
command -v starship >/dev/null && eval "$(starship init zsh)"

# fastfetch solo al abrir una ventana nueva de kitty (no en tmux ni por SSH)
if [[ -z "$TMUX" && -z "$SSH_TTY" && "$(ps -p $PPID -o comm=)" == "kitty" ]]; then
  command -v fastfetch >/dev/null && fastfetch
fi

# === Historial persistente ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY       # agregar, no sobrescribir
setopt INC_APPEND_HISTORY   # guardar cada comando al momento
setopt SHARE_HISTORY        # compartir entre sesiones abiertas
setopt HIST_IGNORE_ALL_DUPS # sin duplicados en todo el historial
setopt HIST_REDUCE_BLANKS

# === Flechas: buscar comandos que empiezan igual ===
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Sugerencias según el historial (paquete zsh-autosuggestions)
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
