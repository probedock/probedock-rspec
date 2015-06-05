
module ProbeDockRSpec

  class Client

    def initialize server, options = {}

      @server = server
      @publish, @local_mode, @workspace = options[:publish], options[:local_mode], options[:workspace]
      @print_payload, @save_payload = options[:print_payload], options[:save_payload]

      @uid = UID.new workspace: @workspace
    end

    def process test_run

      return fail "No server to publish results to" if !@server

      test_run.uid = @uid.load_uid

      payload_options = {}
      return false unless payload = build_payload(test_run, payload_options)

      published = if !@publish
        puts Paint["ProbeDock - Publishing disabled", :yellow]
        false
      elsif publish_payload payload
        true
      else
        false
      end

      save_payload payload if @save_payload
      print_payload payload if @print_payload

      puts

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
      warn Paint["ProbeDock - #{msg}", *styles[type]]
      false
    end

    def print_payload payload
      puts Paint['ProbeDock - Printing payload...', :yellow]
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

      puts Paint["ProbeDock - Sending payload to #{@server.api_url}...", :magenta]

      begin
        if @local_mode
          puts Paint['ProbeDock - LOCAL MODE: not actually sending payload.', :yellow]
        else
          @server.upload payload
        end
        puts Paint["ProbeDock - Done!", :green]
        true
      rescue Server::Error => e
        warn Paint["ProbeDock - Upload failed!", :red, :bold]
        warn Paint["ProbeDock - #{e.message}", :red, :bold]
        if e.response
          warn Paint["ProbeDock - Dumping response body...", :red, :bold]
          warn e.response.body
        end
        false
      end
    end
  end
end
