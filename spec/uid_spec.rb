require 'helper'

describe RoxClient::RSpec::UID do
  include FakeFS::SpecHelpers
  UID ||= RoxClient::RSpec::UID
  ENVIRONMENT_VARIABLE = 'ROX_TEST_RUN_UID'
  UID_REGEXP = /\d{14}\-[a-f0-9]{8}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{12}/

  let(:workspace){ '/tmp' }
  let(:uid_options){ { workspace: workspace } }
  subject{ UID.new uid_options }

  before :each do
    @rox_env_vars = ENV.select{ |k,v| k.match /\AROX_/ }.each_key{ |k| ENV.delete k }
  end

  after :each do
    @rox_env_vars.each_pair{ |k,v| ENV[k] = v }
  end

  describe "#load_uid" do

    it "should not find an uid" do
      expect(subject.load_uid).to be_nil
    end

    it "should read the uid file" do
      FileUtils.mkdir_p File.dirname(uid_file)
      File.open(uid_file, 'w'){ |f| f.write 'abc' }
      expect(subject.load_uid).to eq('abc')
    end

    it "should read the uid environment variable" do
      ENV[ENVIRONMENT_VARIABLE] = 'bcd'
      expect(subject.load_uid).to eq('bcd')
    end

    it "should override the uid file with the environment variable" do
      FileUtils.mkdir_p File.dirname(uid_file)
      File.open(uid_file, 'w'){ |f| f.write 'cde' }
      ENV[ENVIRONMENT_VARIABLE] = 'def'
      expect(subject.load_uid).to eq('def')
    end

    describe "without a workspace" do
      let(:uid_options){ super().tap{ |h| h.delete :workspace } }

      it "should not find the uid file" do
        FileUtils.mkdir_p File.dirname(uid_file)
        File.open(uid_file, 'w'){ |f| f.write 'abc' }
        expect(subject.load_uid).to be_nil
      end
    end
  end

  describe "#generate_uid_to_file" do
    
    it "should generate and save an uid" do
      subject.generate_uid_to_file
      expect(File.read(uid_file)).to match(UID_REGEXP)
    end

    describe "without a workspace" do
      let(:uid_options){ super().tap{ |h| h.delete :workspace } }

      it "should raise an error" do
        expect{ subject.generate_uid_to_file }.to raise_error(UID::Error, /no workspace specified/i)
      end
    end
  end

  describe "#generate_uid_to_env" do
    
    it "should generate and save an uid to the environment" do
      subject.generate_uid_to_env
      expect(ENV[ENVIRONMENT_VARIABLE]).to match(UID_REGEXP)
    end

    describe "when the variable is already defined" do
      before :each do
        ENV[ENVIRONMENT_VARIABLE] = 'abc'
      end

      it "should raise an error" do
        expect{ subject.generate_uid_to_env }.to raise_error(UID::Error, /\$ROX_TEST_RUN_UID is already defined/)
      end
    end
  end

  describe "#clean_uid" do

    before :each do
      FileUtils.mkdir_p File.dirname(uid_file)
      File.open(uid_file, 'w'){ |f| f.write 'abc' }
      ENV[ENVIRONMENT_VARIABLE] = 'bcd'
    end

    it "should clean the uid file" do
      subject.clean_uid
      expect(File.exists?(uid_file)).to be_false
    end

    it "should clean the environment variable" do
      subject.clean_uid
      expect(ENV.key?(ENVIRONMENT_VARIABLE)).to be_false
    end
  end

  def uid_file
    File.join workspace, 'uid'
  end
end
