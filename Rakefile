require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'hoe'

require './lib/rails_conditions.rb'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the Rails Conditions plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the Rails Conditions plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Rails Conditions'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


desc "Publish RDoc to RubyForge"
task :publish_docs => [:rdoc] do
  rubyforge_name = 'railsconditions'
  config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  host = "#{config["username"]}@rubyforge.org"

  remote_dir = "/var/www/gforge-projects/#{rubyforge_name}"
  local_dir = 'rdoc'

  sh %{rsync -av --delete #{local_dir}/ #{host}:#{remote_dir}}
end