
module RoxClient::RSpec

  class Cache

    class Error < RoxClient::RSpec::Error; end

    def initialize options = {}
      @tests = {}
      @workspace, @server_name, @project_api_id = options[:workspace], options[:server_name], options[:project_api_id]
    end

    def save test_run
      validate!

      @tests = { @project_api_id => @tests[@project_api_id] || {} }
      test_run.results.each{ |r| @tests[@project_api_id][r.key] = test_result_hash(r) }

      FileUtils.mkdir_p File.dirname(cache_file)
      File.open(cache_file, 'w'){ |f| f.write Oj.dump(@tests, mode: :strict) }

      self
    end

    def load
      validate!

      @tests = if File.exists? cache_file
        Oj.load(File.read(cache_file), mode: :strict) rescue {}
      else
        {}
      end
      self
    end

    def known? test_result
      @tests[@project_api_id] && !!@tests[@project_api_id][test_result.key]
    end

    def stale? test_result
      @tests[@project_api_id] && test_result_hash(test_result) != @tests[@project_api_id][test_result.key]
    end

    private

    def validate!
      required = { "workspace" => @workspace, "server name" => @server_name, "project API identifier" => @project_api_id }
      missing = required.keys.select{ |k| !required[k] }
      raise Error.new("Missing cache options: #{missing.join ', '}") if missing.any?
    end

    def test_result_hash r
      Digest::SHA2.hexdigest "#{r.name} || #{r.category} || #{r.tags.collect(&:to_s).sort.join(' ')} || #{r.tickets.collect(&:to_s).sort.join(' ')}"
    end

    def cache_file
      @cache_file ||= File.join(@workspace, 'rspec', 'servers', @server_name, 'cache.json')
    end
  end
end
