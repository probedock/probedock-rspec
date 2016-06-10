module ProbeDockRSpec
  def self.config
    @config ||= ProbeDockProbe::Config.new
  end

  def self.config= config
    @config = config
  end

  def self.configure options = {}, &block
    setup! if options.fetch :setup, true
    config.load! &block
    config.project.category ||= 'RSpec'
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
