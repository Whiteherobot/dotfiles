# dotfiles

[![CI](https://github.com/Whiteherobot/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Whiteherobot/dotfiles/actions/workflows/ci.yml)

Mi configuración de escritorio en dos etapas: la actual, sobre [Omarchy](https://omarchy.org)
en CachyOS (2026), y la de junio de 2025, con Arch Linux, Hyprland, Waybar y zsh en una laptop
con GPU NVIDIA.

## Omarchy (actual)

Omarchy trae sus valores por defecto en `~/.local/share/omarchy`. `omarchy/` guarda solo lo
que cambié encima de eso:

| Archivo | Qué hace |
|---|---|
| `hypr/*.lua` | Hyprland con la configuración en Lua: monitores, teclado y touchpad, atajos (incluido 1Password), apariencia y autoarranque |
| `hypr/hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf` | Bloqueo e inactividad, pantalla de bloqueo y luz nocturna |
| `waybar/config.jsonc`, `style.css` | Barra con reloj horizontal y vertical, clima, actualizaciones, grabación de pantalla y el indicador de Jarvis |
| `waybar/scripts/jarvis-indicator.sh` | Muestra si mi asistente por voz está escuchando, pensando o hablando (lee `~/.cache/jarvis-voz/state.json`) |
| `starship.toml` | Prompt de la terminal |

```bash
./install.sh --omarchy --prueba
./install.sh --omarchy
```

## 2025: Arch + Hyprland

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
