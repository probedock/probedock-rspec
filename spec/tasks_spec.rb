require 'helper'

describe ProbeDockRSpec::Tasks do
  include Capture::Helpers
  UID ||= ProbeDockRSpec::UID
  Tasks ||= ProbeDockRSpec::Tasks

  let(:client_options){ { workspace: '/tmp' } }
  let(:config_double){ double client_options: client_options }
  let(:uid_options){ {} }
  let(:uid_double){ double uid_options }
  subject{ Tasks.new }

  before :each do
    Rake::Task.clear
    allow(ProbeDockRSpec).to receive(:config).and_return(config_double)
    allow(UID).to receive(:new).and_return(uid_double)
    subject
  end

  it "should define probe dock rake tasks" do
    expect(task('spec:probe-dock:uid')).not_to be_nil
    expect(task('spec:probe-dock:uid:file')).not_to be_nil
    expect(task('spec:probe-dock:uid:clean')).not_to be_nil
  end

  shared_examples_for "a task" do |task_name,method,error_message|
    let(:uid_double){ double.tap{ |d| allow(d).to receive(method).and_raise(UID::Error.new(error_message)) } }

    it "should output the error message to stderr" do
      c = nil
      expect{ c = capture{ invoke task_name } }.not_to raise_error
      expect(c.stdout).to be_empty
      expect(c.stderr).to match(error_message)
    end

    describe "with trace enabled" do
      before :each do
        options = Rake.application.options
        allow(Rake.application).to receive(:options).and_return(options.dup.tap{ |o| o.trace = true })
      end

      it "should raise the error" do
        expect{ capture{ invoke task_name } }.to raise_error(UID::Error, error_message)
      end
    end
  end

  describe "spec:probe-dock:uid" do
    let(:uid_options){ super().merge generate_uid_to_env: 'abc' }
    before(:each){ expect(UID).to receive(:new).with(client_options) }

    it "should generate an uid in the environment" do
      expect(uid_double).to receive(:generate_uid_to_env)
      capture{ invoke 'spec:probe-dock:uid' }.tap do |c|
        expect(c.stdout).to match(/generated uid/i)
        expect(c.stdout).to match('abc')
      end
    end

    it_should_behave_like "a task", 'spec:probe-dock:uid', :generate_uid_to_env, 'bug1'
  end

  describe "spec:probe-dock:uid:file" do
    let(:uid_options){ super().merge generate_uid_to_file: 'abc' }
    before(:each){ expect(UID).to receive(:new).with(client_options) }

    it "should generate an uid in the uid file" do
      expect(uid_double).to receive(:generate_uid_to_file)
      capture{ invoke 'spec:probe-dock:uid:file' }.tap do |c|
        expect(c.stdout).to match(/generated uid/i)
        expect(c.stdout).to match('abc')
      end
    end

    it_should_behave_like "a task", 'spec:probe-dock:uid:file', :generate_uid_to_file, 'bug2'
  end

  describe "spec:probe-dock:uid:clean" do
    let(:uid_options){ super().merge generate_uid_to_clean: nil }
    before(:each){ expect(UID).to receive(:new).with(client_options) }

    it "should clean the uid" do
      expect(uid_double).to receive(:clean_uid)
      capture{ invoke 'spec:probe-dock:uid:clean' }.tap do |c|
        expect(c.stdout).to match(/cleaned/i)
      end
    end

    it_should_behave_like "a task", 'spec:probe-dock:uid:clean', :clean_uid, 'bug3'
  end

  def invoke name
    task(name).invoke
  end

  def task name
    Rake::Task[name]
  end
end
