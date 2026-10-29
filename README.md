# dotfiles

[![CI](https://github.com/Whiteherobot/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Whiteherobot/dotfiles/actions/workflows/ci.yml)

Configuración de mi laptop **ASUS ROG Strix G16 (G614JV)**, con Intel Core i7-13650HX y NVIDIA RTX 4060 (gráficos híbridos), sobre CachyOS con [Omarchy](https://omarchy.org) (Hyprland).

**Está hecha para esa laptop.** En otra máquina sirve como referencia, pero lo de NVIDIA, el teclado RGB, la tecla de proyectar y el monitor interno dependen de este modelo.

Esta laptop recibió muchas críticas desde que salió. Al pasarla a Linux, casi todos los problemas resultaron ser de configuración y no del equipo. Este repo junta esos arreglos para no tener que descubrirlos otra vez: se clona, se corre el instalador y queda igual.

## Cómo se ve

![Escritorio con la barra de Omarchy y los widgets de pendientes y calendario (tareas de ejemplo)](docs/img/1-escritorio.jpg)

| Lanzador de apps (`SUPER + ALT + SPACE`) | Menú de Omarchy (`SUPER + SPACE`) |
| --- | --- |
| ![Lanzador de apps](docs/img/2-lanzador.jpg) | ![Menú de Omarchy](docs/img/4-menu.jpg) |

![Ventanas en mosaico: fastfetch, btop y los atajos](docs/img/3-mosaico.jpg)

![Paleta del tema Aether](docs/img/paleta.png)

- **Tema:** Aether, una paleta propia en salvia y verde azulado. Es la misma que usan Pliego y Forjia. El fondo es [wallhaven-xekydd](https://wallhaven.cc/w/xekydd); el instalador lo descarga desde su fuente original, no va en el repo. Neovim usa `aether.nvim` con la misma paleta (`neovim.lua` del tema). Los temas sin `neovim.lua` propio lo reciben de `config/omarchy/themed/neovim.lua.tpl`, que Omarchy rellena con los colores del tema al aplicarlo; sin eso LazyVim falla con `Failed to load plugins.theme`.
- **Barra:** la de Omarchy (Quickshell, desde la versión "quattro"; antes era Waybar). A la derecha suma un ecualizador de música con cava (`config/omarchy/bar/modules/visualizer.qml`), que se oculta en silencio y funciona con Apple Music, Spotify, YouTube y cualquier otro audio.
- **Panel de agentes:** copia del panel de Omarchy (`ing_michi.agents`) con pestañas cortas y logos propios. Además de Claude muestra GitHub Copilot, Faro (el LLM local) y Gemini (`agy`); cada uno tiene un script `omarchy-agent-usage-*` que un timer corre cada 5 minutos.
- **Teclado:** toma el color del tema. Con música, pulsa con los graves. Si tienes un juego con el foco (Steam/Proton, gamescope o cualquier app que se declare juego), toma el color dominante de su ventana: la lee cada 3 s al 5 % de tamaño, solo en memoria, y no mira el resto de la pantalla. Si no, y lo que suena tiene carátula (una canción en Spotify o Apple Music, un video de YouTube), toma su color. Sin nada de eso (una llamada) pulsa con el color del tema, y en silencio vuelve a él. `Super + Shift + Ctrl + K` lo apaga todo.

## Qué resuelve

| Problema en esta laptop | Arreglo | Archivo |
|---|---|---|
| Video con tirones y lag en multimedia: el panel cuelga de la Intel y todo se copiaba desde la NVIDIA | La decodificación de video pasa a la Intel (`LIBVA_DRIVER_NAME=iHD`) y el compositor sigue en NVIDIA. Mover la GPU primaria a la Intel rompe el login en este equipo | `config/uwsm/env.d/99-omarchy-upgrade-env` |
| Se colgaba al reanudar desde hibernación y había que forzar el apagado | El driver de NVIDIA ya no entra en el initramfs | `sistema/etc/mkinitcpio.conf.d/99-sin-nvidia-temprano.conf` |
| La hibernación perdía la sesión (`failed to quiesce async: error -5`) | La VRAM se guarda en `/var/tmp` y se habilitan `nvidia-suspend`, `nvidia-hibernate` y `nvidia-resume` | `sistema/etc/modprobe.d/nvidia-sleep.conf`, `sistema/instalar-sistema.sh` |
| La tecla de proyectar (Super+P) solo achicaba ventanas | Menú para duplicar, extender o usar solo la pantalla externa, como Win+P | `bin/pantalla-modo`, `config/hypr/bindings.lua` |
| El monitor interno quedaba apagado al desconectar el externo | Se recupera solo al iniciar la sesión | `config/systemd/user/omarchy-recover-internal-monitor.service` |
| Pedía dos contraseñas al arrancar | Autologin de SDDM más hyprlock al iniciar: se escribe una sola vez. El tema del login vive en ese mismo archivo, así que no hay que borrarlo | `sistema/etc/sddm.conf.d/autologin.conf`, `config/hypr/autostart.lua` |
| Docker sin acceso a la GPU y con logs que crecían sin límite | Runtime de NVIDIA y logs rotados (5 × 10 MB) | `sistema/etc/docker/daemon.json` |
| El Omarchy nuevo ya no evita el bloqueo con el cargador puesto | Enchufada no se bloquea ni apaga la pantalla; con batería vuelve el bloqueo normal | `bin/ac-stay-awake`, `config/systemd/user/ac-stay-awake.service` |
| Actualizar el día que sale un kernel o un driver NVIDIA con fallas | Aviso de actualización como mucho una vez por semana, y solo cuando los paquetes delicados (kernel, NVIDIA, Hyprland, Omarchy…) llevan 3 días publicados. Clic en el aviso para actualizar | `bin/aviso-actualizaciones`, `config/systemd/user/actualizaciones-aviso.timer` |
| El teclado RGB (una sola zona) no seguía el tema | Color del tema y modo reactivo a la música, con pocos cambios para no gastar el disco (asusd reescribe su configuración en cada cambio) | `bin/kbd-music`, `config/cava/keyboard.conf` |

## Qué incluye

```
config/hypr/          Hyprland en Lua (atajos, monitores, apariencia, entrada) y hypridle/hyprlock/hyprsunset
config/uwsm/env.d/    variables de la sesión (GPU híbrida)
config/cava/          ecualizador de la barra y graves para el teclado
config/omarchy/       tema Aether, barra (shell.json + ecualizador) y panel de agentes
config/quickshell/    widgets del escritorio: pendientes, calendario y música
config/faro/          LLM local: Modelfile, ajustes de SearXNG e ícono
config/systemd/user/  teclado reactivo, monitor interno, LLM local, cargador, avisos y uso de agentes
bin/                  kbd-music, pantalla-modo, llm-cargador, faro-abrir, escritorio, ac-stay-awake,
                      aviso-actualizaciones, omarchy-agent-usage-{copilot,faro,antigravity}
sistema/etc/          arreglos de sistema (se copian aparte, con sudo)
```

## Instalar

Requiere Omarchy instalado sobre CachyOS (o Arch).

```bash
git clone https://github.com/Whiteherobot/dotfiles.git ~/dotfiles
cd ~/dotfiles
omarchy pkg add cava playerctl jq asusctl imagemagick   # instala solo los que falten
./install.sh --prueba             # muestra qué haría, sin tocar nada
./install.sh                      # enlaza la configuración y respalda lo que exista
omarchy theme set Aether
omarchy restart shell
sudo ./sistema/instalar-sistema.sh   # muestra cada cambio en /etc y pide confirmación
```

- `install.sh` enlaza cada archivo en su lugar. `shell.json` y el panel de agentes se copian, porque Omarchy reescribe `shell.json` y rompería el enlace. Lo que ya exista se mueve a `~/.dotfiles-respaldo/<fecha>/`. Correrlo de nuevo no cambia nada.
- Pide la versión "quattro" de Omarchy o una más nueva: la configuración de Hyprland guarda solo los cambios propios y la barra es la de Omarchy.
- `instalar-sistema.sh` muestra la diferencia de cada archivo de `/etc` antes de instalarlo, guarda una copia del anterior y, si cambió el initramfs, ofrece regenerarlo. El autologin queda con el usuario que corre el script. Reiniciar al terminar.

## Atajos propios

| Atajo | Qué hace |
|---|---|
| `Super + P` o tecla de proyectar | Elegir cómo usar una pantalla externa o un proyector |
| `Super + Shift + Ctrl + M` | Apple Music (app web, como WhatsApp en Omarchy) |
| `Super + Shift + Ctrl + K` | Prender o apagar el teclado reactivo a la música |
| `Super + I` | Abrir Faro, el asistente local (ver abajo) |
| `Super + D` | Pendientes, calendario y música encima de todo (Esc o clic fuera para cerrar) |

## Widgets del escritorio

Tarjetas de vidrio arriba a la derecha hechas con [Quickshell](https://quickshell.org), que toman los colores del tema:

- **Pendientes:** un checklist en Markdown (`- [ ]` por hacer, `- [/]` en curso, `- [x]` hecho), que se puede editar a mano o en Obsidian. Clic en el círculo la marca hecha y clic en el texto la pone en curso. El encabezado abre un tablero kanban. Si una tarea termina en `[[Nota]]`, el tablero muestra el avance de esa nota.
- **Calendario:** Google Calendar por su dirección secreta iCal (solo lectura, sin OAuth). Soporta eventos repetidos y funciona sin conexión con la última copia.
- **Ahora suena:** carátula, barras (cava) y controles; se oculta sin música.

Requiere `quickshell` y Node 22.18 o más nuevo (corre TypeScript directo) (`omarchy pkg add quickshell`, Node con `mise use -g node`). La configuración es local y no va al repo:

```bash
mkdir -p ~/.config/escritorio
# Opcional: dónde está el archivo de pendientes (por defecto ~/Documents/Pendientes.md)
echo '{ "pendientes": "~/Notas/Pendientes.md", "notas": "~/Notas" }' > ~/.config/escritorio/config.json
# Calendario: Google Calendar → Configuración → tu calendario → "Dirección secreta en formato iCal"
echo 'Personal | https://calendar.google.com/calendar/ical/…/basic.ics' > ~/.config/escritorio/calendarios.txt
chmod 600 ~/.config/escritorio/calendarios.txt
escritorio tarea agregar "Probar los widgets"
```

## LLM local (opcional)

Un asistente que corre en la GPU, sin nube: [Ollama](https://ollama.com) con Qwen3.5 9B, [Open WebUI](https://openwebui.com) como app ("Faro", `Super + I`) y [SearXNG](https://searxng.org) para que busque en la web. Solo escucha en `127.0.0.1`.

Se prende al conectar el cargador y se apaga con batería (`llm-cargador`), porque la GPU la drena y calienta la laptop. El cargador de esta laptop tiene microcortes, así que espera 60 s sin corriente antes de apagarlo.

```bash
# con ollama y docker instalados, install.sh genera las claves y activa llm-cargador
ollama pull qwen3.5:9b
ollama create faro -f config/faro/Modelfile
```

- Si el adaptador no es `ADP0`, cambiarlo con `LLM_ADAPTADOR` (ver `ls /sys/class/power_supply`).
- Las claves (`~/.local/share/faro/secreto.env` y la de SearXNG) se generan en cada instalación y no van al repo.
- Para que busque en la web, en Open WebUI: *Ajustes de administración → Búsqueda web → SearXNG*, con `http://127.0.0.1:8888/search?q=<query>`.

## Menú de arranque (Limine)

No va al instalador porque lleva el UUID del disco. En `/etc/default/limine` se agregó esto, para que el menú tenga solo los kernels de CachyOS y sus snapshots, sin Windows ni la entrada «EFI fallback»:

```bash
FIND_BOOTLOADERS=no
BOOT_ORDER="linux-cachyos, linux-cachyos-lts, *, *fallback, Snapshots"
```

## Historia

En 2025 era una configuración de Arch con Hyprland y zsh. En octubre de 2026 pasé a Omarchy sobre CachyOS, y este repo pasó a guardar solo la configuración actual, con los arreglos que fueron saliendo en el uso diario. Lo anterior sigue en la etiqueta [`config-2025`](https://github.com/Whiteherobot/dotfiles/tree/config-2025).

## Licencia

MIT. Ver [LICENSE](LICENSE).
