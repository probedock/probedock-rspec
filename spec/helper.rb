require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'simplecov'
require 'coveralls'
Coveralls.wear!

SimpleCov.formatters = [
  Coveralls::SimpleCov::Formatter,
  SimpleCov::Formatter::HTMLFormatter
]

SimpleCov.start

require 'rspec'
require 'rspec/its'
require 'rspec/collection_matchers'
require 'fakefs/spec_helpers'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each{ |f| require f }

require 'probe-dock-rspec'
