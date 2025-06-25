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

# NVIDIA GPU Environment (Wayland / Hyprland)
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia


export PATH="$HOME/.local/bin:$PATH"
