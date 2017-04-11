# config valid only for Capistrano 3.4
lock '3.4.0'

set :application, 'my_app_name'
set :repo_url, 'git@github.com:giveone/giveone.git'
set :branch, 'master'
set :keep_releases, 5
# set :rbenv_ruby, '2.1.10'
set :delayed_job_server_role, :jobs # Re: https://github.com/collectiveidea/delayed_job/wiki/Delayed-Job-tasks-for-Capistrano-3
set :delayed_job_args, "-n 1"

# NB: we need to include :jobs in here so DJ can use assets in emails
set :assets_roles, [:web, :app, :jobs]

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/apps/my_app_name"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Don't regenerate binstubs from bundler
set :bundle_binstubs, nil

set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets}
set :linked_files, %w{
  config/database.yml
  config/secrets.yml
}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :logs do
  desc "tail rails logs"
  task :tail_rails do
    on roles(:app) do
      execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log"
    end
  end
end

namespace :deploy do
  desc "Initial setup"
  task :setup do
    on roles(:all) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/tmp/cache"
      execute "mkdir -p #{shared_path}/tmp/sockets"
      info "\n\n\n\n\n\n\n\n*********************"
      info "NOTICE: Now edit the config files in #{shared_path}."
      info "\n\n\n\n\n\n\n\n*********************"
    end
  end


  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:all) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        info "WARNING: HEAD is not the same as origin/master"
        info "Run `git push` to sync changes."
        exit
      end
    end
  end

  before "deploy", "deploy:check_revision"

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :groups, limit: 2, wait: 5 do
      execute "/etc/init.d/unicorn_rails restart"
    end
    on roles(:jobs), in: :parallel do
      invoke 'delayed_job:restart'
    end
  end
  after :publishing, :restart

  namespace :nginx do
    desc 'Restart web (nginx)'
    task :restart do
      on roles(:web), in: :parallel do
        execute "sudo nginx -s reload"
      end
    end
  end
end
