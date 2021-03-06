set :runner, 'apache'
set :user, 'root'

set :domain, 'appserver2.lrdesign.com'
set :application, 'tracks'      # eg 'rfx'
set :deploy_to, "/var/www/tracks.lrdesign.com"
set :keep_releases, 10
set :branch, 'production'
set :rails_env, "production"
set :use_sudo, false
