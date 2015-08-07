APP_ROOT = File.expand_path("../..", __FILE__)

worker_processes Integer(ENV["UNICORN_PROCESSES"] || 2)
working_directory APP_ROOT
#user 'app', 'app'

stderr_path "#{APP_ROOT}/log/unicorn.stderr.log"
stdout_path "#{APP_ROOT}/log/unicorn.stdout.log"

listen "#{APP_ROOT}/tmp/sockets/unicorn.sock"
pid "#{APP_ROOT}/tmp/pids/unicorn.pid"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = File.expand_path('Gemfile', APP_ROOT)
end

before_fork do |server, worker|
  STDERR.puts "Before Fork"
  old_pid = "#{ server.config[:pid] }.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
      STDERR.puts "send signal: #{sig} #{File.read(old_pid)}"
    rescue Errno::ENOENT, Errno::ESRCH
      STDERR.puts "Before Fork Error"
    end
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  STDERR.puts "After Fork"
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end

