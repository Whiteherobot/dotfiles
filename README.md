# dotfiles

[![CI](https://github.com/Whiteherobot/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Whiteherobot/dotfiles/actions/workflows/ci.yml)

Mi configuración de escritorio de junio de 2025: Arch Linux con Hyprland,
Waybar y zsh, en una laptop con GPU NVIDIA.

| Archivo | Qué hace |
|---|---|
| `hypr/hyprland.conf` | Hyprland con kitty, Dolphin y Wofi; bordes en degradado, blur y animaciones; variables de entorno para NVIDIA. |
| `waybar/config`, `waybar/style.css` | Barra superior con espacios de trabajo, ventana activa, reloj, volumen, batería y bandeja. Usa los íconos de `otf-font-awesome`. |
| `zsh/.zshrc` | Historial compartido entre sesiones, búsqueda con las flechas, autosugerencias, prompt Starship y fastfetch al abrir kitty. |

## Instalar

```bash
git clone https://github.com/Whiteherobot/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --prueba   # muestra lo que va a hacer
./install.sh
```

El script enlaza cada archivo en su lugar y mueve lo que ya existía a
`~/.dotfiles-respaldo/<fecha>/`. Paquetes que usa la configuración: `hyprland`,
`waybar`, `kitty`, `dolphin`, `wofi`, `otf-font-awesome`, `starship`,
`fastfetch`, `zsh-autosuggestions`, `brightnessctl` y `playerctl`.

## Historia

Es la configuración que usé antes de pasarme a [Omarchy](https://omarchy.org)
sobre CachyOS. En 2026 se corrigió lo que impedía usarla en otra máquina:
`hyprland.conf` arrancaba un `start.sh` que nunca se subió (la barra no
aparecía), las variables de NVIDIA estaban en la shell en lugar de Hyprland y un
alias `copilot` instalaba la extensión de VS Code cada vez. Se agregaron el
script de instalación y una CI que lo prueba en un `HOME` vacío.

Licencia MIT.
