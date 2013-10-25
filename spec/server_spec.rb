require 'helper'

describe RoxClient::RSpec::Server do
  let(:api_key_id){ '0123456789' }
  let(:api_key_secret){ 'abcdefghijklmnopqrstuvwxyz' }
  let(:options){ {
    name: 'A server',
    api_url: 'http://example.com/api',
    api_key_id: api_key_id,
    api_key_secret: api_key_secret,
    api_version: 42,
    project_api_id: '0000000000'
  } }
  let(:server){ RoxClient::RSpec::Server.new options }
  subject{ server }

  it "should set its attributes" do
    expect(options.keys.inject({}){ |memo,k| memo[k] = subject.send(k); memo }).to eq(options)
  end

  describe "without an api version" do
    let(:options){ super().delete_if{ |k,v| k == :api_version } }
    its(:api_version){ should eq(1) }
  end

  it "should create payload options" do
    expect(subject.payload_options).to eq(version: 42)
  end

  describe "#upload" do
    let(:payload){ { 'foo' => 'bar' } }
    let(:http_responses){ [] }

    before :each do
      ENV.delete_if{ |k,v| k.match(/\AROX_/) }
      HTTParty.stub(:get){ http_responses.shift }
      HTTParty.stub(:post){ http_responses.shift }
    end

    describe "when everything works" do
      let(:api_root_body){ '{"_links":{"v1:test-payloads":{"href":"http://example.com/api/payloads"}}}' }
      let(:api_root_response){ double code: 200, content_type: 'application/hal+json', body: api_root_body }
      let(:payload_response){ double code: 202 }
      let(:http_responses){ [ api_root_response, payload_response ] }
      let(:authentication_headers){ { 'Authorization' => %|RoxApiKey id="#{api_key_id}" secret="#{api_key_secret}"| } }
      let(:payload_headers){ { 'Content-Type' => 'application/vnd.lotaris.rox.payload.v1+json' } }

      it "should not raise an error" do
        expect_upload.not_to raise_error
      end

      it "should GET the API root" do
        expect(HTTParty).to receive(:get).once.with('http://example.com/api', headers: authentication_headers )
        subject.upload payload
      end

      it "should POST the payload" do
        headers = payload_headers.merge authentication_headers
        expect(HTTParty).to receive(:post).once.with('http://example.com/api/payloads', body: Oj.dump(payload, mode: :strict), headers: headers)
        subject.upload payload
      end
    end

    describe "when the API root is inaccessible" do
      let(:api_root_response){ double code: 500 }
      let(:http_responses){ [ api_root_response ] }

      it "should raise an error" do
        expect_upload.to raise_server_error(/expected http 200 OK/i, res: api_root_response)
      end
    end

    describe "when the API root has the wrong content type" do
      let(:api_root_response){ double code: 200, content_type: 'application/json' }
      let(:http_responses){ [ api_root_response ] }

      it "should raise an error" do
        expect_upload.to raise_server_error(/application\/hal\+json/, res: api_root_response)
      end
    end

    describe "when the API root has no v1:test-payloads link" do
      let(:api_root_body){ '{"_links":{"self":{"href":"http://example.com/api"}}}' }
      let(:api_root_response){ double code: 200, content_type: 'application/hal+json', body: api_root_body }
      let(:http_responses){ [ api_root_response ] }

      it "should raise an error" do
        expect_upload.to raise_server_error(/v1:test-payloads link/, res: api_root_response)
      end
    end

    describe "when the payload is not accepted" do
      let(:api_root_body){ '{"_links":{"v1:test-payloads":{"href":"http://example.com/api/payloads"}}}' }
      let(:api_root_response){ double code: 200, content_type: 'application/hal+json', body: api_root_body }
      let(:payload_response){ double code: 401 }
      let(:http_responses){ [ api_root_response, payload_response ] }

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

    describe "without an api key id" do
      let(:options){ super().delete_if{ |k,v| k == :api_key_id } }
      it "should raise an error" do
        expect_upload.to raise_server_error(/missing/, /apiKeyId/)
      end
    end

    describe "without an api key secret" do
      let(:options){ super().delete_if{ |k,v| k == :api_key_secret } }
      it "should raise an error" do
        expect_upload.to raise_server_error(/missing/, /apiKeySecret/)
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
    raise_error RoxClient::RSpec::Server::Error do |err|
      args.each{ |m| expect(err.message).to match(m) }
      expect(err.response).to options[:res] ? be(options[:res]) : be_nil
    end
  end
end
