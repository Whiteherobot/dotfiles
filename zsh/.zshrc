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

# Copilot CLI (solo como recordatorio de instalación si luego lo quieres usar)
alias copilot='code --install-extension GitHub.copilot'
