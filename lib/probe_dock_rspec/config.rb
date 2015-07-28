module ProbeDockRSpec

  def self.config
    @config ||= ProbeDockProbe::Config.new
  end

  def self.configure options = {}, &block
    config.load! &block
    setup! if options.fetch :setup, true
    config
  end

  private

  def self.setup!
    unless @setup
      @setup = true
      ::RSpec.configure do |c|
        c.add_formatter Formatter
      end
    end
  end
end
