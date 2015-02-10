require 'yaml'

# Utilities to send test results to Probe Dock.
module ProbeDockRSpec

  def self.config
    @config ||= Config.new.tap(&:load)
  end

  def self.configure options = {}
    yield config if block_given?
    config.load_warnings.each{ |w| warn Paint["Probe Dock - #{w}", :yellow] }
    config.setup! if options[:setup] != false
    config
  end

  class Config
    # TODO: add silent/verbose option(s)
    class Error < ProbeDockRSpec::Error; end
    attr_writer :publish, :local_mode, :cache_payload, :print_payload, :save_payload
    attr_reader :project, :server, :workspace, :load_warnings

    def initialize
      @servers = []
      @project = Project.new
      @publish, @local_mode, @cache_payload, @print_payload, @save_payload = false, false, false, false, false
      @load_warnings = []
    end

    def workspace= dir
      @workspace = dir ? File.expand_path(dir) : nil
    end

    def servers
      @servers.dup
    end

    # Plugs Probe Dock utilities into RSpec.
    def setup!
      ::RSpec.configure do |c|
        c.add_formatter Formatter
      end
    end

    %w(publish local_mode cache_payload print_payload save_payload).each do |name|
      define_method("#{name}?"){ instance_variable_get("@#{name}") }
    end

    def client_options
      {
        publish: @publish,
        local_mode: @local_mode,
        workspace: @workspace,
        cache_payload: @cache_payload,
        print_payload: @print_payload,
        save_payload: @save_payload
      }.select{ |k,v| !v.nil? }
    end

    def load

      @load_warnings = []
      return unless config = load_config_files

      @publish = parse_env_flag :publish, !!config[:publish]
      @server_name = parse_env_option(:server) || config[:server]
      @local_mode = parse_env_flag(:local) || !!config[:local]

      self.workspace = parse_env_option(:workspace) || config[:workspace]
      @cache_payload = parse_env_flag :cache_payload, !!config[:payload][:cache]
      @print_payload = parse_env_flag :print_payload, !!config[:payload][:print]
      @save_payload = parse_env_flag :save_payload, !!config[:payload][:save]

      @servers, @server = build_servers config

      if @servers.empty?
        @load_warnings << "No server defined"
      elsif !@server_name
        @load_warnings << "No server name given"
      elsif !@server
        @load_warnings << "Unknown server '#{@server_name}'"
      end

      project_options = config[:project]
      project_options.merge! api_id: @server.project_api_id if @server and @server.project_api_id
      @project.update project_options

      self
    end

    private

    def build_servers config

      default_server_options = { project_api_id: config[:project][:api_id] }
      servers = config[:servers].inject({}) do |memo,(name, options)|
        memo[name] = Server.new default_server_options.merge(options).merge(name: name)
        memo
      end

      [ servers.values, servers[@server_name.to_s.strip] ]
    end

    def load_config_files

      configs = [ home_config_file, working_config_file ]
      actual_configs = configs.select{ |f| File.exists? f }

      if actual_configs.empty?
        @load_warnings << %|no config file found, looking for:\n     #{configs.join "\n     "}|
        return false
      end

      actual_configs.collect!{ |f| YAML.load_file f }

      actual_configs.inject({ servers: {} }) do |memo,yml|
        memo.merge! parse_general_options(yml)

        if yml['servers'].kind_of? Hash
          yml['servers'].each_pair do |k,v|
            if v.kind_of? Hash
              memo[:servers][k] = (memo[:servers][k] || {}).merge(parse_server_options(v))
            end
          end
        end

        memo[:payload] = (memo[:payload] || {}).merge parse_payload_options(yml['payload'])
        memo[:project] = (memo[:project] || {}).merge parse_project_options(yml['project'])

        memo
      end
    end

    def home_config_file
      File.join File.expand_path('~'), '.probe-dock', 'config.yml'
    end

    def working_config_file
      File.expand_path ENV['PROBE_DOCK_CONFIG'] || 'probe-dock.yml', Dir.pwd
    end

    def parse_env_flag name, default = false
      val = parse_env_option name
      val ? !!val.to_s.strip.match(/\A(1|t|true)\Z/i) : default
    end

    def parse_env_option name
      var = "PROBE_DOCK_#{name.upcase}"
      ENV.key?(var) ? ENV[var] : nil
    end

    def parse_general_options h
      parse_options h, %w(publish server local workspace)
    end

    def parse_server_options h
      parse_options h, %w(name apiUrl apiKeyId apiKeySecret apiVersion projectApiId)
    end

    def parse_payload_options h
      parse_options h, %w(save cache print)
    end

    def parse_project_options h
      # TODO: remove project name once API v0 is dead
      parse_options h, %w(name version apiId category tags tickets)
    end

    def parse_options h, keys
      return {} unless h.kind_of? Hash
      keys.inject({}){ |memo,k| memo[k.gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym] = h[k] if h.key?(k); memo }
    end
  end
end
