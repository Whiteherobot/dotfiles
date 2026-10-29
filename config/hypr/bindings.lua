-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- [Michi] personalizaciones migradas desde Omarchy 3.8.5
hl.unbind("SUPER + I")
o.bind("SUPER + I", "Faro: asistente local", "faro-abrir")
o.bind("SUPER + D", "Escritorio: pendientes y calendario", "quickshell -c escritorio ipc call escritorio alternar")
o.bind("SUPER + SHIFT + CTRL + M", "Apple Music", { webapp = "https://music.apple.com/", focus = true })
o.bind("SUPER + SHIFT + CTRL + K", "Teclado musical", "kbd-music-toggle")

-- Modo de pantalla externa / proyector (la tecla de proyectar manda SUPER + P).
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Pantalla externa / proyector", "pantalla-modo")
o.bind("XF86Display", "Pantalla externa / proyector", "pantalla-modo")
o.bind("SUPER + ALT + P", "Pseudo window", hl.dsp.window.pseudo())
