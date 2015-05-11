require 'helper'

describe ProbeDockRSpec::Formatter do
  Client ||= ProbeDockRSpec::Client
  TestRun ||= ProbeDockRSpec::TestRun
  Formatter ||= ProbeDockRSpec::Formatter

  let(:server_double){ double }
  let(:client_options){ { publish: true } }
  let(:project_double){ double }
  let(:config_double){ double server: server_double, client_options: client_options, project: project_double }
  let(:client_double){ double process: nil }
  let(:run_double){ double :end_time= => nil, :duration= => nil, :add_result => nil }
  subject{ new_formatter }

  before :each do
    allow(ProbeDockRSpec).to receive(:config).and_return(config_double)
    allow(Client).to receive(:new).and_return(client_double)
    allow(TestRun).to receive(:new).and_return(run_double)
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

      allow(Time).to receive(:now).and_return(now)
      subject.start 0

      empty_group = group_double "Pending"
      subject.example_group_started double(group: empty_group)
      subject.example_group_finished double(group: empty_group)
    end

    it "should set the end time and duration when stopped" do
      end_time = now + 12
      expect(run_double).to receive(:duration=).with(12000)
      allow(Time).to receive(:now).and_return(end_time)
      subject.stop double
    end

    it "should send the test run to be processed by the client when dumping the summary" do
      expect(client_double).to receive(:process).with(run_double)
      subject.stop double
      subject.close double
    end
  end

  describe "in example groups" do
    let(:example_groups){ [ group_double('Group A'), group_double('Group B') ] }
    before :each do
      subject.start 2
      example_groups.each{ |g| subject.example_group_started double(group: g) }
    end
    
    it "should add a successful result to the test run" do

      ex = example_double 'should work'

      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      subject.example_started double(example: ex)

      expect(run_double).to receive(:add_result).with(ex, example_groups, passed: true, duration: 3000)

      allow(Time).to receive(:now).and_return(now + 3)
      subject.example_passed double(example: ex)
    end

    it "should add a failed result to the test run" do

      error = runtime_error 'bug'
      ex = example_double 'should probably work', exception: error

      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      subject.example_started double(example: ex)

      expected_message = Array.new.tap do |a|
        a << "foo"
        a << "  line1"
        a << "  line2"
        a << "  # a"
        a << "  # b"
        a << "  # c"
      end.join "\n"

      expect(run_double).to receive(:add_result).with(ex, example_groups, passed: false, duration: 2000, message: expected_message)

      allow(Time).to receive(:now).and_return(now + 2)
      subject.example_failed double(example: ex, description: 'foo', message_lines: %w(line1 line2), formatted_backtrace: %w(a b c))
    end
  end

  def new_formatter
    Formatter.new nil
  end

  def group_double desc, options = {}
    probe_dock_metadata = { probe_dock: options.delete(:metadata) || {} }
    double options.merge(description: desc, metadata: probe_dock_metadata)
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
