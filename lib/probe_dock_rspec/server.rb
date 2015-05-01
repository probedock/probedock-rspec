require 'oj'
require 'httparty'

module ProbeDockRSpec

  class Server
    attr_reader :name, :api_url, :api_token, :api_version, :project_api_id

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
      @api_token = options[:api_token].to_s if options[:api_token]
      @api_version = options[:api_version] || 1
      @project_api_id = options[:project_api_id].to_s if options[:project_api_id]
    end

    def payload_options
      { version: @api_version }
    end

    def upload payload
      validate!

      body = Oj.dump payload, mode: :strict
      res = HTTParty.post payload_uri, body: body, headers: payload_headers

      if res.code != 202
        raise Error.new("Expected HTTP 202 Accepted when submitting payload, got #{res.code}", res)
      end
    end

    private

    def validate!
      required = { "apiUrl" => @api_url }
      required.merge!({ "apiToken" => @api_token, "projectApiId" => @project_api_id }) if @api_version >= 1
      missing = required.inject([]){ |memo,(k,v)| v.to_s.strip.length <= 0 ? memo << k : memo }
      raise Error.new("Server #{@name} is missing the following options: #{missing.join ', '}") if missing.any?
    end

    def payload_headers
      { 'Authorization' => "Bearer #{@api_token}", 'Content-Type' => 'application/vnd.probe-dock.payload.v1+json' }
    end

    def payload_uri
      "#{@api_url}/publish"
    end
  end
end
