-- Extra autostart processes.
-- hl.on("hyprland.start", function()
--   hl.exec_cmd("uwsm-app -- my-service")
-- end)
o.exec_on_start("hyprlock")

-- Widgets del escritorio: pendientes, calendario y música.
o.exec_on_start("uwsm-app -- quickshell -c escritorio")
