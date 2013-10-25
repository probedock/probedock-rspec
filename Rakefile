# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rox-client-rspec"
  gem.homepage = "https://github.com/lotaris/rox-client-rspec"
  gem.license = "MIT"
  gem.summary = %Q{RSpec extensions to send results to ROX Center.}
  gem.description = %Q{Assigns keys to tests and sends the results of a run to ROX Center.}
  gem.email = "simon.oulevay@lotaris.com"
  gem.authors = ["Simon Oulevay"]
  gem.files = Dir["lib/**/*.rb"] + %w(Gemfile LICENSE.txt README.md VERSION)
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

# version tasks
require 'rake-version'
RakeVersion::Tasks.new do |v|
  v.copy 'lib/rox-client-rspec.rb'
end

# release task
desc 'Release gem to Lotaris'
task :release => [ :gemspec, :build, :inabox ]

VERSION = File.open('VERSION', 'r').read
GEM_HOST = 'http://10.10.201.4:9292'

desc 'Push gem to Lotaris'
task :inabox do |t|
  raise "Could not push gem to #{GEM_HOST}" unless system "gem inabox pkg/rox-client-rspec-#{VERSION}.gem -g #{GEM_HOST}"
end

require 'rspec/core/rake_task'
desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  #t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

task :default => :spec
