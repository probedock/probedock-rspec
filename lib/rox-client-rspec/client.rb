
module RoxClient::RSpec

  class Client

    def initialize server, options = {}

      @server = server
      @publish, @local_mode, @workspace = options[:publish], options[:local_mode], options[:workspace]
      @cache_payload, @print_payload, @save_payload = options[:cache_payload], options[:print_payload], options[:save_payload]
      
      cache_options = { workspace: @workspace }
      cache_options.merge! server_name: @server.name, project_api_id: @server.project_api_id if @server
      @cache = Cache.new cache_options

      @uid = UID.new workspace: @workspace
    end

    def process test_run

      puts
      return fail "No server to publish results to" if !@server

      test_run.uid = @uid.load_uid

      payload_options = @server.payload_options

      cache_enabled = @cache_payload && load_cache
      payload_options[:cache] = @cache if cache_enabled

      return false unless payload = build_payload(test_run, payload_options)

      published = if !@publish
        puts Paint["ROX - Publishing disabled", :yellow]
        false
      elsif publish_payload payload
        @cache.save test_run if cache_enabled
        true
      else
        false
      end

      save_payload payload if @save_payload
      print_payload payload if @print_payload

      published
    end

    private

    def build_payload test_run, options = {}
      begin
        TestPayload.new(test_run).to_h options
      rescue PayloadError => e
        fail e.message
      end
    end

    def fail msg, type = :error
      styles = { warning: [ :yellow ], error: [ :bold, :red ] }
      warn Paint["ROX - #{msg}", *styles[type]]
      false
    end

    def load_cache
      begin
        @cache.load
      rescue Cache::Error => e
        warn Paint["ROX - #{e.message}", :yellow]
        false
      end
    end

    def print_payload payload
      puts Paint['ROX - Printing payload...', :yellow]
      begin
        puts JSON.pretty_generate(payload)
      rescue
        puts payload.inspect
      end
    end

    def save_payload payload

      missing = { "workspace" => @workspace, "server" => @server }.inject([]){ |memo,(k,v)| !v ? memo << k : memo }
      return fail "Cannot save payload without a #{missing.join ' and '}" if missing.any?

      FileUtils.mkdir_p File.dirname(payload_file)
      File.open(payload_file, 'w'){ |f| f.write Oj.dump(payload, mode: :strict) }
    end

    def payload_file
      @payload_file ||= File.join(@workspace, 'rspec', 'servers', @server.name, 'payload.json')
    end

    def publish_payload payload

      puts Paint["ROX - Sending payload to #{@server.api_url}...", :magenta]

      begin
        if @local_mode
          puts Paint['ROX - LOCAL MODE: not actually sending payload.', :yellow]
        else
          @server.upload payload
        end
        puts Paint["ROX - Done!", :green]
        true
      rescue Server::Error => e
        warn Paint["ROX - Upload failed!", :red, :bold]
        warn Paint["ROX - #{e.message}", :red, :bold]
        if e.response
          warn Paint["ROX - Dumping response body...", :red, :bold]
          warn e.response.body
        end
        false
      end
    end
  end
end
