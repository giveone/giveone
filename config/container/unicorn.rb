# Sample verbose configuration file for Unicorn (not Rack)
#
# This configuration file documents many features of Unicorn
# that may not be needed for some applications. See
# http://unicorn.bogomips.org/examples/unicorn.conf.minimal.rb
# for a much simpler configuration file.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.

# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
unicorn_worker_processes = ENV["UNICORN_WORKER_PROCESSES"].to_i
if unicorn_worker_processes == 0
  worker_processes 2
else
  worker_processes unicorn_worker_processes
end

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
#
APP_PATH = "/app"
Unicorn::HttpServer::START_CTX[0] = "#{APP_PATH}/bin/unicorn"

# Since Unicorn is never exposed to outside clients, it does not need to
# run on the standard HTTP port (80), there is no reason to start Unicorn
# as root unless it's from system init scripts.
# If running the master process as root and the workers as an unprivileged
# user, do this to switch euid/egid in the workers (also chowns logs):
# user "unprivileged_user", "unprivileged_group"

working_directory APP_PATH # available in 0.94.0+

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
# listen APP_PATH + '/pids/unicorn.sock', tcp_nopush: false
listen ENV["UNICORN_LISTEN_PORT"].to_i, tcp_nopush: false


# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 430

# feel free to point this anywhere accessible on the filesystem
pid APP_PATH + "/pids/unicorn-#{ENV["UNICORN_LISTEN_PORT"]}.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path APP_PATH + "/log/unicorn.stderr.log"
stdout_path APP_PATH + "/log/unicorn.stdout.log"

# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
# preload_app true
# GC.respond_to?(:copy_on_write_friendly=) and
#   GC.copy_on_write_friendly = true

# Enable this flag to have unicorn test client connections by writing the
# beginning of the HTTP headers before calling the application.  This
# prevents calling the application for connections that have disconnected
# while queued.  This is only guaranteed to detect clients on the same
# host unicorn runs on, and unlikely to detect disconnects even on a
# fast LAN.
check_client_connection false

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{APP_PATH}/Gemfile"
end

# adapted from http://unicorn.bogomips.org/examples/unicorn.conf.rb
before_fork do |server, worker|
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!
  # Throttle the master from forking too quickly by sleeping.
  sleep 1
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.establish_connection
end
