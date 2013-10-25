require 'helper'

describe RoxClient::RSpec::Formatter do
  Client ||= RoxClient::RSpec::Client
  TestRun ||= RoxClient::RSpec::TestRun
  Formatter ||= RoxClient::RSpec::Formatter

  let(:server_double){ double }
  let(:client_options){ { publish: true } }
  let(:project_double){ double }
  let(:config_double){ double server: server_double, client_options: client_options, project: project_double }
  let(:client_double){ double process: nil }
  let(:run_double){ double :end_time= => nil, :duration= => nil, :add_result => nil }
  subject{ new_formatter }

  before :each do
    RoxClient::RSpec.stub config: config_double
    Client.stub new: client_double
    TestRun.stub new: run_double
  end

  describe "when created" do
    subject{ Formatter }

    it "should create a client" do
      expect(Client).to receive(:new).with(server_double, client_options)
      new_formatter
    end

    it "should create a test run" do
      expect(TestRun).to receive(:new).with(project_double)
      new_formatter
    end
  end

  describe "with an empty test run" do
    let(:now){ Time.now }
    before :each do

      Time.stub now: now
      subject.start 0

      empty_group = group_double "Pending"
      subject.example_group_started empty_group
      subject.example_group_finished empty_group
    end

    it "should set the end time and duration when stopped" do
      end_time = now + 12
      expect(run_double).to receive(:end_time=).with(end_time.to_i * 1000)
      expect(run_double).to receive(:duration=).with(12000)
      Time.stub now: end_time
      subject.stop
    end

    it "should send the test run to be processed by the client when dumping the summary" do
      expect(client_double).to receive(:process).with(run_double)
      subject.stop
      subject.dump_summary 12, 0, 0, 0
    end
  end

  describe "in example groups" do
    let(:example_groups){ [ group_double('Group A'), group_double('Group B') ] }
    before :each do
      subject.start 2
      example_groups.each{ |g| subject.example_group_started g }
    end
    
    it "should add a successful result to the test run" do

      ex = example_double 'should work'

      now = Time.now
      Time.stub now: now
      subject.example_started ex

      expect(run_double).to receive(:add_result).with(ex, example_groups, passed: true, duration: 3000)

      Time.stub now: now + 3
      subject.example_passed ex
    end

    it "should add a failed result to the test run " do

      error = runtime_error 'bug'
      ex = example_double 'should probably work', exception: error

      now = Time.now
      Time.stub now: now
      subject.example_started ex

      subject.stub read_failed_line: 'line 1'
      subject.stub(:format_backtrace){ |backtrace,*args| backtrace }

      expected_message = Array.new.tap do |a|
        a << "Group A Group B should probably work"
        a << "Failure/Error: line 1"
        a << "  RuntimeError:"
        a << "    bug"
        error.backtrace.each do |line|
          a << "# #{line}"
        end
      end.join "\n"

      expect(run_double).to receive(:add_result).with(ex, example_groups, passed: false, duration: 2000, message: expected_message)

      Time.stub now: now + 2
      subject.example_failed ex
    end
  end

  def new_formatter
    Formatter.new nil
  end

  def group_double desc, options = {}
    rox_metadata = { rox: options.delete(:metadata) || {} }
    double options.merge(description: desc, metadata: rox_metadata)
  end

  def example_double desc, options = {}
    execution_result = { exception: options.delete(:exception) }
    double options.merge(description: desc, execution_result: execution_result)
  end

  def runtime_error msg
    begin
      raise msg
    rescue RuntimeError => e
      e
    end
  end
end
