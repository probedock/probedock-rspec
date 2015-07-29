module ProbeDockRSpec

  def self.configure options = {}, &block
    ProbeDockProbe.config.load! &block
    setup! if options.fetch :setup, true
    ProbeDockProbe.config
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
