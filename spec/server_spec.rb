require 'helper'

describe ProbeDockRSpec::Server do
  let(:api_token){ 'abcdefghijklmnopqrstuvwxyz' }
  let :options do
    {
      name: 'A server',
      api_url: 'http://example.com/api',
      api_token: api_token,
      project_api_id: '0000000000'
    }
  end
  let(:server){ ProbeDockRSpec::Server.new options }
  subject{ server }

  it "should set its attributes" do
    expect(options.keys.inject({}){ |memo,k| memo[k] = subject.send(k); memo }).to eq(options)
  end

  describe "#upload" do
    let(:payload){ { 'foo' => 'bar' } }
    let(:http_responses){ [] }

    before :each do
      ENV.delete_if{ |k,v| k.match(/\APROBE_DOCK_/) }
      allow(HTTParty).to receive(:get){ http_responses.shift }
      allow(HTTParty).to receive(:post){ http_responses.shift }
    end

    describe "when everything works" do
      let(:payload_response){ double code: 202 }
      let(:http_responses){ [ payload_response ] }
      let(:authentication_headers){ { 'Authorization' => "Bearer #{api_token}" } }
      let(:payload_headers){ { 'Content-Type' => 'application/vnd.probe-dock.payload.v1+json' } }

      it "should not raise an error" do
        expect_upload.not_to raise_error
      end

      it "should POST the payload" do
        headers = payload_headers.merge authentication_headers
        expect(HTTParty).to receive(:post).once.with('http://example.com/api/publish', body: Oj.dump(payload, mode: :strict), headers: headers)
        subject.upload payload
      end
    end

    describe "when the payload is not accepted" do
      let(:payload_response){ double code: 401 }
      let(:http_responses){ [ payload_response ] }

      it "should raise an error" do
        expect_upload.to raise_server_error(/expected http 202 accepted/i, res: payload_response)
      end
    end

    describe "without an api url" do
      let(:options){ super().delete_if{ |k,v| k == :api_url } }
      it "should raise an error" do
        expect_upload.to raise_server_error(/missing/, /apiUrl/)
      end
    end

    describe "without an api token" do
      let(:options){ super().delete_if{ |k,v| k == :api_token } }
      it "should raise an error" do
        expect_upload.to raise_server_error(/missing/, /apiToken/)
      end
    end

    describe "without a project api id" do
      let(:options){ super().delete_if{ |k,v| k == :project_api_id } }
      it "should raise an error" do
        expect_upload.to raise_server_error(/missing/, /projectApiId/)
      end
    end
  end

  def expect_upload
    expect{ subject.upload payload }
  end

  def raise_server_error *args
    options = args.last.kind_of?(Hash) ? args.pop : {}
    raise_error ProbeDockRSpec::Server::Error do |err|
      args.each{ |m| expect(err.message).to match(m) }
      expect(err.response).to options[:res] ? be(options[:res]) : be_nil
    end
  end
end
