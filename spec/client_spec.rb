require 'helper'
require 'json'

describe ProbeDockRSpec::Client do
  include Capture::Helpers
  include FakeFS::SpecHelpers

  NO_SERVER_MSG = /no server/i
  PUBLISHING_DISABLED_MSG = /publishing disabled/i
  PRINTING_PAYLOAD_MSG = /printing payload/i
  CANNOT_SAVE_MSG = /cannot save payload/i
  SENDING_PAYLOAD_MSG = /sending payload/i
  LOCAL_MODE_MSG = /local mode/i
  DONE_MSG = /done/i
  UPLOAD_FAILED_MSG = /upload failed/i
  DUMPING_RESPONSE_MSG = /response body/i
  ALL_MESSAGES = [
    NO_SERVER_MSG, PUBLISHING_DISABLED_MSG, PRINTING_PAYLOAD_MSG, CANNOT_SAVE_MSG,
    SENDING_PAYLOAD_MSG, LOCAL_MODE_MSG, DONE_MSG, UPLOAD_FAILED_MSG, DUMPING_RESPONSE_MSG
  ]
  API_URL = 'http://example.com/api'
  WORKSPACE = '/tmp'

  let(:cache_double){ double }
  let(:payload_to_h){ { 'foo' => 'bar' } }
  let(:payload_double){ double to_h: payload_to_h }
  let(:uid_double){ double load_uid: '42' }
  let(:run_double){ double :uid= => nil }

  let(:server_options){ { name: 'A server', api_url: API_URL, project_api_id: '0123456789', upload: nil } }
  let(:server){ double server_options }
  let(:client_options){ { publish: true, workspace: WORKSPACE } }
  let(:client){ ProbeDockRSpec::Client.new server, client_options }
  subject{ client }

  before :each do
    allow(ProbeDockRSpec::Cache).to receive(:new).and_return(cache_double)
    allow(ProbeDockRSpec::TestPayload).to receive(:new).and_return(payload_double)
    allow(ProbeDockRSpec::UID).to receive(:new).and_return(uid_double)
  end

  describe "when created" do
    subject{ ProbeDockRSpec::Client }

    it "should create a cache manager" do
      expect(ProbeDockRSpec::Cache).to receive(:new).with(workspace: WORKSPACE, server_name: server_options[:name], project_api_id: server_options[:project_api_id])
      ProbeDockRSpec::Client.new server, client_options
    end

    it "should not raise an error if the server is missing" do
      expect(ProbeDockRSpec::Cache).to receive(:new).with(workspace: WORKSPACE)
      expect{ ProbeDockRSpec::Client.new nil, client_options }.not_to raise_error
    end

    it "should create an uid manager" do
      expect(ProbeDockRSpec::UID).to receive(:new).with(workspace: WORKSPACE)
      ProbeDockRSpec::Client.new server, client_options
    end
  end

  it "should upload the results payload" do
    expect(ProbeDockRSpec::TestPayload).to receive(:new).with(run_double)
    expect(payload_double).to receive(:to_h).with({})
    expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG
  end

  it "should set the test run uid" do
    expect(run_double).to receive(:uid=).with('42')
    expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG
  end

  describe "in local mode" do
    let(:client_options){ super().merge local_mode: true }
    it "should not upload results" do
      expect(server).not_to receive(:upload)
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, LOCAL_MODE_MSG, DONE_MSG
    end
  end

  describe "with no server" do
    let(:server){ nil }
    it "should warn that there is no server" do
      expect_processed false, stderr: [ NO_SERVER_MSG ]
    end
  end

  describe "when the payload cannot be serialized" do
    before(:each){ allow(payload_double).to receive(:to_h).and_raise(ProbeDockRSpec::PayloadError.new('bug')) }
    it "should output the error to stderr" do
      expect_processed false, stderr: [ 'bug' ]
    end
  end

  describe "when publishing is disabled" do
    let(:client_options){ super().merge publish: false }
    it "should not upload the payload" do
      expect(server).not_to receive(:upload)
      expect_processed false, PUBLISHING_DISABLED_MSG
    end
  end

  describe "when publishing fails due to a configuration error" do
    it "should output the error message to stderr" do
      allow(server).to receive(:upload).and_raise(ProbeDockRSpec::Server::Error.new("bug"))
      expect_processed false, SENDING_PAYLOAD_MSG, API_URL, stderr: [ UPLOAD_FAILED_MSG, 'bug' ]
    end
  end

  describe "when publishing fails due to a server error" do
    it "should output the error message and response body to stderr" do
      allow(server).to receive(:upload).and_raise(ProbeDockRSpec::Server::Error.new("bug", double(body: 'fubar')))
      expect_processed false, SENDING_PAYLOAD_MSG, API_URL, stderr: [ UPLOAD_FAILED_MSG, 'bug', DUMPING_RESPONSE_MSG, 'fubar' ]
    end
  end

  describe "with payload caching enabled" do
    let(:client_options){ super().merge cache_payload: true }
    before :each do
      allow(cache_double).to receive(:load).and_return(cache_double)
      allow(cache_double).to receive(:save).and_return(cache_double)
    end

    it "should load the cache" do
      expect(cache_double).to receive(:load)
      expect(payload_double).to receive(:to_h).with(cache: cache_double)
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG
    end

    it "should output any error to stderr and not save the cache" do
      allow(cache_double).to receive(:load).and_raise(ProbeDockRSpec::Cache::Error.new('bug'))
      expect(cache_double).not_to receive(:save)
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG, stderr: [ 'bug' ]
    end

    it "should not save the cache if publishing fails" do
      allow(server).to receive(:upload).and_raise(ProbeDockRSpec::Server::Error.new("bug"))
      expect(cache_double).to receive(:load)
      expect(cache_double).not_to receive(:save)
      expect_processed false, SENDING_PAYLOAD_MSG, API_URL, stderr: [ UPLOAD_FAILED_MSG, 'bug' ]
    end
  end

  describe "with payload printing enabled" do
    let(:client_options){ super().merge print_payload: true }

    it "should print the payload" do
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG, PRINTING_PAYLOAD_MSG, JSON.pretty_generate(payload_to_h)
    end

    it "should use inspect if the payload can't be pretty-printed" do
      allow(JSON).to receive(:pretty_generate).and_raise(StandardError.new('bug'))
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG, PRINTING_PAYLOAD_MSG, payload_to_h.inspect
    end
  end

  describe "with payload saving enabled" do
    let(:client_options){ super().merge save_payload: true }
    let(:payload_file){ File.join WORKSPACE, 'rspec', 'servers', server_options[:name], 'payload.json' }

    it "should save the payload" do
      FileUtils.mkdir_p File.dirname(payload_file)
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG
      expect_payload_to_be_saved
    end

    it "should create the workspace directory" do
      expect_processed true, SENDING_PAYLOAD_MSG, API_URL, DONE_MSG
      expect(File.directory?(File.dirname(payload_file))).to be(true)
      expect_payload_to_be_saved
    end

    def expect_payload_to_be_saved
      expect(File.read(payload_file)).to eq(Oj.dump(payload_to_h, mode: :strict))
    end
  end

  def expect_processed result, *args

    options = args.last.kind_of?(Hash) ? args.pop : {}
    messages = args
    warnings = options[:stderr] || []

    capture_process.tap do |c|

      expect(c.result).to be(result)
      if messages.empty?
        expect(c.stdout.strip).to eq('')
      else
        messages.each{ |m| expect(c.stdout).to match(m) }
      end

      if warnings.empty?
        expect(c.stderr).to eq('')
      else
        warnings.each{ |m| expect(c.stderr).to match(m) }
      end

      ensure_no_match c.output, *(ALL_MESSAGES - messages - warnings)

      yield c if block_given?
    end
  end

  def ensure_no_match string, *matches
    matches.each{ |m| expect(string).not_to match(m) }
  end

  def capture_process
    capture{ client.process run_double }
  end
end
