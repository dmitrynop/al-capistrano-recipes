Capistrano::Configuration.instance.load do

  # Where your nginx lives. Usually /opt/nginx or /usr/local/nginx for source compiled.
  set :nginx_sites_enabled_path, "/etc/nginx/sites-enabled" unless exists?(:nginx_sites_enabled_path)

  # Server names. Defaults to application name.
  set :server_names, "#{application}_#{rails_env}" unless exists?(:server_names)

  # Path to the nginx erb template to be parsed before uploading to remote
  set(:nginx_local_config) { "#{templates_path}/nginx.conf.erb" } unless exists?(:nginx_local_config)

  # Path to where your remote config will reside (I use a directory sites inside conf)
  set(:nginx_remote_config) do
    File.join("#{shared_path}", "config", "nginx_#{application}_#{rails_env}.conf")
  end unless exists?(:nginx_remote_config)

  set :nginx_site_symlink_sites_enabled, File.join(nginx_sites_enabled_path, "#{application}_#{rails_env}") unless exists?(:nginx_site_symlink_sites_enabled)


    set :nginx_unicorn_init_d, "nginx_unicorn"
    set :nginx_unicorn_root, "/opt/nginx_unicorn"
    set :nginx_unicorn_conf_path, File.join(File.dirname(__FILE__),'nginx.conf')
    set(:nginx_unicorn_conf_dir) {"#{nginx_unicorn_root}/conf"}
    set :nginx_unicorn_init_d_path, File.join(File.dirname(__FILE__),'nginx_unicorn.init')
    set :nginx_unicorn_stub_conf_path, File.join(File.dirname(__FILE__),'stub_status.conf')
    set :nginx_unicorn_god_path, File.join(File.dirname(__FILE__),'nginx_unicorn.god')
    set :nginx_unicorn_logrotate_path, File.join(File.dirname(__FILE__),'nginx_unicorn.logrotate')
    #set :nginx_unicorn_src, "http://nginx.org/download/nginx-1.0.6.tar.gz"
    set :nginx_unicorn_src,"http://nginx.org/download/nginx-1.2.1.tar.gz"
    set(:nginx_unicorn_ver) { nginx_unicorn_src.match(/\/([^\/]*)\.tar\.gz$/)[1] }
    set(:nginx_unicorn_source_dir) {"#{nginx_unicorn_root}/src/#{nginx_unicorn_ver}"}
    set(:nginx_unicorn_patch_dir) {"#{nginx_unicorn_root}/src"}
    set(:nginx_unicorn_upstream_socket){"#{shared_path}/sockets/unicorn.sock"}
    set :nginx_unicorn_app_conf_path, File.join(File.dirname(__FILE__),'app.conf')
    set(:nginx_unicorn_configure_flags) {[
      "--prefix=#{nginx_unicorn_root}",
      "--sbin-path=#{nginx_unicorn_sbin_file}",
      "--pid-path=#{nginx_unicorn_pid_file}",
      "--with-debug",
      "--with-http_gzip_static_module",
      #"--with-http_stub_status_module",
      "--with-http_ssl_module",
      #"--add-module=#{nginx_unicorn_patch_dir}/nginx_syslog_patch",
      "--add-module=#{nginx_unicorn_patch_dir}/nginx-x-rid-header",
      "--with-ld-opt=-lossp-uuid",
      "--with-cc-opt=-I/usr/include/ossp"
    ]}








  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    desc "|capistrano-recipes| Parses and uploads nginx configuration for this app."
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(nginx_local_config, nginx_remote_config,true)
      # create symbolic link on ubuntu
      sudo <<-CMD
        ln -s -f "#{nginx_remote_config}" "#{nginx_site_symlink_sites_enabled}"
      CMD
    end

    # this should be done through apt-get or similar...

    # desc "|capistrano-recipes| Bootstraps Nginx to init.d"
    # task :setup_init, :roles => :app do
    #   upload nginx_init_local, nginx_init_temp, :via => :scp
    #   sudo "mv #{nginx_init_temp} #{nginx_init_remote}"
    #   # Allow executing the init.d script
    #   sudo "chmod +x #{nginx_init_remote}"
    #   # Make it run at bootup
    #   sudo "update-rc.d nginx defaults"
    # end
 desc 'Installs nginx for unicorn - dont working'
    task :install, :roles => :app do
      utilities.apt_install "libssl-dev zlib1g-dev libcurl4-openssl-dev libpcre3-dev libossp-uuid-dev"
      sudo "mkdir -p #{nginx_unicorn_source_dir}"
      run "cd #{nginx_unicorn_root}/src && #{sudo} wget --tries=2 -c --progress=bar:force #{nginx_unicorn_src} && #{sudo} tar zxvf #{nginx_unicorn_ver}.tar.gz"
      utilities.git_clone_or_pull "git://github.com/yaoweibin/nginx_syslog_patch.git", "#{nginx_unicorn_patch_dir}/nginx_syslog_patch"
      utilities.git_clone_or_pull "git://github.com/newobj/nginx-x-rid-header.git", "#{nginx_unicorn_patch_dir}/nginx-x-rid-header"
      run "cd #{nginx_unicorn_source_dir} && #{sudo} sh -c 'patch -p1 < #{nginx_unicorn_patch_dir}/nginx_syslog_patch/syslog_#{nginx_unicorn_ver.split('-').last}.patch'"
      run "cd #{nginx_unicorn_source_dir} && #{sudo} ./configure #{nginx_unicorn_configure_flags.join(" ")} && #{sudo} make"
      run "cd #{nginx_unicorn_source_dir} && #{sudo} make install"
    end

    desc "|capistrano-recipes| Parses config file and outputs it to STDOUT (internal task)"
    task :parse, :roles => :app , :except => { :no_release => true } do
      puts parse_config(nginx_local_config)
    end

    desc "|capistrano-recipes| Restart nginx"
    task :restart, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx restart"
    end

    desc "|capistrano-recipes| Stop nginx"
    task :stop, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx stop"
    end

    desc "|capistrano-recipes| Start nginx"
    task :start, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx start"
    end

    desc "|capistrano-recipes| Show nginx status"
    task :status, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx status"
    end

    desc "|capistrano-recipes| Enable nginx site"
    task :enable, :roles => :app , :except => { :no_release => true } do
      sudo "nxensite #{application}_#{rails_env}"
    end

    desc "|capistrano-recipes| Disable nginx site"
    task :disable, :roles => :app , :except => { :no_release => true } do
      sudo "nxdissite #{application}_#{rails_env}"
    end
  end

  after 'deploy:setup' do
    nginx.setup if Capistrano::CLI.ui.agree("Create nginx configuration file? [Yn]")
  end if is_using('nginx',:web_server)
end

