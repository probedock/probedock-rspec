require 'oj'
require 'httparty'

module ProbeDockRSpec

  class Server
    attr_reader :name, :api_url, :api_key_id, :api_key_secret, :api_version, :project_api_id

    class Error < ProbeDockRSpec::Error
      attr_reader :response
    
      def initialize msg, response = nil
        super msg
        @response = response
      end
    end

    def initialize options = {}
      @name = options[:name].to_s.strip
      @api_url = options[:api_url].to_s if options[:api_url]
      @api_key_id = options[:api_key_id].to_s if options[:api_key_id]
      @api_key_secret = options[:api_key_secret].to_s if options[:api_key_secret]
      @api_version = options[:api_version] || 1
      @project_api_id = options[:project_api_id].to_s if options[:project_api_id]
    end

    def payload_options
      { version: @api_version }
    end

    def upload payload
      validate!

      uri = payload_uri
      body = Oj.dump payload, mode: :strict

      res = case @api_version
      when 0
        HTTParty.post uri, body: body
      else
        HTTParty.post uri, body: body, headers: payload_headers.merge(authentication_headers)
      end

      if res.code != 202
        raise Error.new("Expected HTTP 202 Accepted when submitting payload, got #{res.code}", res)
      end
    end

    private

    def validate!
      
      raise Error.new("Server #{@name} requires $PROBE_DOCK_RUNNER_KEY to be set (API v0)") if @api_version == 0 and !ENV['PROBE_DOCK_RUNNER_KEY']

      required = { "apiUrl" => @api_url }
      required.merge!({ "apiKeyId" => @api_key_id, "apiKeySecret" => @api_key_secret, "projectApiId" => @project_api_id }) if @api_version >= 1
      missing = required.inject([]){ |memo,(k,v)| v.to_s.strip.length <= 0 ? memo << k : memo }
      raise Error.new("Server #{@name} is missing the following options: #{missing.join ', '}") if missing.any?
    end

    def payload_headers
      { 'Content-Type' => 'application/vnd.42inside.probe-dock.payload.v1+json' }
    end

    def payload_uri
      case @api_version

      when 0
        "#{@api_url}/v1/payload"

      else
      
        # get api root
        res = HTTParty.get @api_url, headers: authentication_headers
        if res.code != 200
          raise Error.new("Expected HTTP 200 OK status code for API root, got #{res.code}", res)
        elsif res.content_type != 'application/hal+json'
          raise Error.new("Expected API root in the application/hal+json content type, got #{res.content_type}", res)
        end

        body = Oj.load res.body, mode: :strict

        links = body['_links'] || {}
        if !links.key?('v1:test-payloads')
          raise Error.new("Expected API root to have a v1:test-payloads link", res)
        end

        # extract payload uri
        links['v1:test-payloads']['href']
      end
    end

    def authentication_headers
      { 'Authorization' => %|ProbeDockApiKey id="#{@api_key_id}" secret="#{@api_key_secret}"| }
    end
  end
end
