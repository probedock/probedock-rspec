# encoding: UTF-8
require 'rspec'

module ProbeDockRSpec
  VERSION = '0.5.1'

  class Error < StandardError; end
  class PayloadError < Error; end
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }
