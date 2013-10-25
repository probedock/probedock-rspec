
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

=begin
  def expect_success output = nil, &block
    c = capture &block
    expect(c.stdout).to(output ? match(output) : be_empty)
    expect(c.stderr).to be_empty
    c.result
  end

  def expect_failure message, code = 1

    stderr = StringIO.new
    $stderr = stderr
    expect{ yield }.to raise_error(SystemExit){ |e| expect(e.status).to eq(code) }
    $stderr = STDERR

    if message.kind_of? Regexp
      expect(stderr.string.strip).to match(message)
    end
  end

  def expect_error type
    stdout, stderr = StringIO.new, StringIO.new
    $stdout, $stderr = stdout, stderr
    expect{ yield }.to raise_error(type)
    $stdout, $stderr = STDOUT, STDERR
  end
=end
end
