require 'oj'
require 'httparty'

module ProbeDockRSpec

  class Server
    attr_accessor :name, :api_url, :api_token, :project_api_id

    class Error < ProbeDockRSpec::Error
      attr_reader :response

      def initialize msg, response = nil
        super msg
        @response = response
      end
    end

    def initialize options = {}
      @name = options[:name].to_s.strip if options[:name]
      @api_url = options[:api_url].to_s if options[:api_url]
      @api_token = options[:api_token].to_s if options[:api_token]
      @project_api_id = options[:project_api_id].to_s if options[:project_api_id]
    end

    def clear
      @name = nil
      @api_url = nil
      @api_token = nil
      @project_api_id = nil
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
      required = { "name" => @name, "apiUrl" => @api_url, "apiToken" => @api_token, "projectApiId" => @project_api_id }
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
