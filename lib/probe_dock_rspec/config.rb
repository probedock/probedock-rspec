module ProbeDockRSpec
  def self.config
    @config ||= ProbeDockProbe::Config.new
  end

  def self.config= config
    @config = config
  end

  def self.configure options = {}, &block
    setup! if options.fetch :setup, true
    config.project.category = 'RSpec'
    config.load! &block
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
