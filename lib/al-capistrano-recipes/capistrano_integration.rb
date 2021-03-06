require 'capistrano'
require 'capistrano/version'
require 'capistrano/cli'

#require '../../lib/al-capistrano-recipes/helpers'

# =========================================================================
# These are helper methods that will be available to your recipes.
# =========================================================================

# automatically sets the environment based on presence of
# :stage (multistage gem), :rails_env, or RAILS_ENV variable; otherwise defaults to 'production'
#module AlCapistranoRecipes
 # class CapistranoIntegration
#def self.load_into(capistrano_config)
 #     capistrano_config.load do

def environment
  if exists?(:stage)
    stage
  elsif exists?(:rails_env)
    rails_env
  elsif(ENV['RAILS_ENV'])
    ENV['RAILS_ENV']
  else
    "production"
  end
end

def is_using_nginx
  is_using('nginx',:web_server)
end

def is_using_passenger
  is_using('passenger',:app_server)
end

def is_using_unicorn
  is_using('unicorn',:app_server)
end

def is_app_monitored?
  is_using('bluepill', :monitorer) || is_using('god', :monitorer)
end

def is_using(something, with_some_var)
  exists?(with_some_var.to_sym) && fetch(with_some_var.to_sym).to_s.downcase == something
end

# Path to where the generators live
def templates_path
  expanded_path_for('/generators')
end

def docs_path
  expanded_path_for('/doc')
end

def expanded_path_for(path)
  e = File.join(File.dirname(__FILE__),path)
  File.expand_path(e)
end

def parse_config(file)
  require 'erb'  #render not available in Capistrano 2
  template=File.read(file)          # read it
  return ERB.new(template).result(binding)   # parse it
end

# =========================================================================
# Prompts the user for a message to agree/decline
# =========================================================================
def ask(message, default=true)
  Capistrano::CLI.ui.agree(message)
end

# Generates a configuration file parsing through ERB
# Fetches local file and uploads it to remote_file
# Make sure your user has the right permissions.
def generate_config(local_file,remote_file,use_sudo=false)
  temp_file = '/tmp/' + File.basename(local_file)
  buffer    = parse_config(local_file)
  File.open(temp_file, 'w+') { |f| f << buffer }
  upload temp_file, temp_file, :via => :scp
  run "#{use_sudo ? sudo : ""} mv #{temp_file} #{remote_file}"
  `rm #{temp_file}`
end

#==========================================================================


#==========================================================================

  def apt_install(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get} -qyu --force-yes install #{packages.join(" ")}"
  end

  # utilities.apt_reinstall %w[package1 package2]
  # utilities.apt_reinstall "package1 package2"
  def apt_reinstall(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get} -qyu --force-yes --reinstall install #{packages.join(" ")}"
  end

  def apt_remove(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get} -qyu --force-yes remove #{packages.join(" ")}"
  end

  def apt_autoremove
    sudo "#{apt_get} -qy autoremove"
  end

  def apt_update
    sudo "#{apt_get} -qy update"
  end

  def apt_upgrade
    sudo_with_input "dpkg --configure -a", /\?/, "\n" #recover from failed dpkg
    sudo "#{apt_get} -qy update"
    sudo_with_input "#{apt_get} -qyu --force-yes upgrade", /\?/, "\n" #answer the default if any package pops up a warning
  end

  def apt_get
    "DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get"
  end






# =========================================================================
# Executes a basic rake task.
# Example: run_rake log:clear
# =========================================================================
def run_rake(task)
  run "cd #{current_path} && rake #{task} RAILS_ENV=#{environment}"
end


#Dir[File.join(File.dirname(__FILE__), '/ruby/*.rb')].sort.each { |lib| load lib }

#  end
#end
#end
#end

#if Capistrano::Configuration.instance
#  AlCapistranoRecipes::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
#end
Dir[File.join(File.dirname(__FILE__), '/recipes/*.rb')].sort.each { |f| load f }

