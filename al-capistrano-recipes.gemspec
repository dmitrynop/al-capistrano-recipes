# -*- encoding: utf-8 -*-
require File.expand_path('../lib/al-capistrano-recipes/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'al-capistrano-recipes'
  gem.version     = AlRecipes::VERSION.dup
  gem.author      = 'Al Bobrov'
  gem.email       = 'mister-al@ya.ru'
  gem.homepage    = 'https://github.com/misteral'
  gem.summary     = %q{recipes for Capistrano}
  gem.description = %q{Capistrano plugin that integrates server and etc tasks.}

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'

  gem.add_dependency "capistrano", ">= 2.5.9"
  gem.add_dependency "capistrano-ext", ">= 1.2.1"
end
