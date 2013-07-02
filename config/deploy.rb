require "bundler/capistrano"

set :rvm_ruby_string, 'ruby-1.9.2'
require "rvm/capistrano"                               # Load RVM's capistrano plugin.

set :application, "self_service_kiosk"
set :repository,  "git@github.com:thirtysixthspan/self_service_kiosk.git"

set :domain, "self_service_kiosk.com"
set :template_dir, "config/"
set :deploy_via, :remote_cache
set :deploy_to, "/srv/www/#{domain}"
set :user, "deployer"
set :use_sudo,  false
set :scm, :git
set :bundle_flags,    "--deployment"

task :production do
  server "self_service_kiosk.com", :app, :web, :db, :primary => true
end

task :staging do
  server "stage", :app, :web, :db, :primary => true  
end

default_run_options[:pty] = true
set :ssh_options, {:forward_agent => true}

namespace :tail do
  task :unicorn do
    run "tail -n 250 /srv/www-log/#{domain}/*.log" do |ch, stream, out|
      puts out
    end
  end
end

namespace :dev do
  namespace :retrieve do
    task :database do
      system('/etc/init.d/redis stop')
      download('/srv/redis/appendonly.aof','/srv/redis/appendonly.aof')
      download('/srv/redis/dump.rdb','/srv/redis/dump.rdb')
      system('/etc/init.d/redis start')
    end
  end
end

namespace :deploy do
  task :full do
    deploy.setup
    deploy.check
    deploy.packages
    deploy.update
    deploy.install
    deploy.seed
    deploy.start
    deploy.cleanup
  end
  
  task :packages do
    run "#{sudo} apt-get -y install libxml2-dev libxslt-dev"    
  end
  task :install do
    run "cd #{deploy_to}/current; #{sudo} bash install"
  end
  task :seed do
    run "cd #{deploy_to}/current; rake db:seed"
  end
  task :start do 
    run "/etc/init.d/#{domain} start" do |ch, stream, out|
      puts out
      if out =~ /Passphrase:/
        passphrase = STDIN.gets
        ch.send_data passphrase 
      end
    end
  end
  task :stop do
    run "/etc/init.d/#{domain} stop"
  end
  task :finalize_update do
    #override defaults
  end
end
