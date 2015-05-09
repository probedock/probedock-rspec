require 'fileutils'
require 'digest/sha2'

module ProbeDockRSpec

  class TestPayload

    class Error < ProbeDockRSpec::Error; end

    def initialize run
      @run = run
    end

    def to_h options = {}
      @run.to_h options
    end
  end
end
