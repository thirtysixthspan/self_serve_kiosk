worker_processes 4

working_directory "/srv/www/self_service_kiosk.com/current"

listen "/srv/sockets/self_service_kiosk.socket"
timeout 500
pid "/srv/pids/self_service_kiosk.com/unicorn.pid"
stderr_path "/srv/www-log/self_service_kiosk.com/unicorn.stderr.log"
stdout_path "/srv/www-log/self_service_kiosk.com/unicorn.stdout.log"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

after_fork do |server, worker|
  port = 5000 + worker.nr

  child_pid = server.config[:pid].sub('.pid', ".#{port}.pid")
  system("echo #{Process.pid} > #{child_pid}")
end


