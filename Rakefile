require "bundler/gem_tasks"
require "rspec/core/rake_task"
Dir.glob('tasks/*.rake').each { |r| import r }

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new
