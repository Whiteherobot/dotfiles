-- Extra autostart processes.
-- hl.on("hyprland.start", function()
--   hl.exec_cmd("uwsm-app -- my-service")
-- end)
o.exec_on_start("hyprlock")

-- Dojo: widgets de práctica (racha y pendientes).
o.exec_on_start("uwsm-app -- quickshell -c dojo")
