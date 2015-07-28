class Capture
  module Helpers
    def capture *args, &block
      Capture.capture *args, &block
    end
  end

  attr_reader :result, :stdout, :stderr

  def initialize options = {}
    @result, @stdout, @stderr = options[:result], options[:stdout], options[:stderr]
  end

  def output join = nil
    "#{@stdout}#{join}#{@stderr}"
  end

  def self.capture &block
    result = nil
    stdout, stderr = StringIO.new, StringIO.new
    $stdout, $stderr = stdout, stderr
    result = block.call if block_given?
    $stdout, $stderr = STDOUT, STDERR
    new result: result, stdout: stdout.string, stderr: stderr.string
  end
end
