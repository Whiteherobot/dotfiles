-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- [Michi] personalizaciones migradas desde Omarchy 3.8.5
o.exec_on_start("omarchy-system-lock")

-- Widgets del escritorio: pendientes, calendario y música.
o.exec_on_start("uwsm-app -- quickshell -c escritorio")
