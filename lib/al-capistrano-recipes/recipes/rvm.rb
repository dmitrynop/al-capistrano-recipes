namespace :rvm do
  task :create_gemset do
    run "rvm gemset create 1.9.3-p194-perf@#{application}"
  end
end

