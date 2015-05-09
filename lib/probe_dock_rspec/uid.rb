require 'securerandom'

module ProbeDockRSpec

  class UID
    ENVIRONMENT_VARIABLE = 'PROBE_DOCK_TEST_REPORT_UID'

    class Error < ProbeDockRSpec::Error; end

    def initialize options = {}
      @workspace = options[:workspace]
    end

    def load_uid
      if env_var
        return env_var
      elsif @workspace
        current_uid
      end
    end

    def generate_uid_to_file
      raise Error.new("No workspace specified; cannot save test run UID") if !@workspace
      generate_uid.tap{ |uid| save_uid uid }
    end

    def generate_uid_to_env
      raise Error.new("$PROBE_DOCK_TEST_REPORT_UID is already defined") if env_var
      ENV[ENVIRONMENT_VARIABLE] = generate_uid
    end

    def clean_uid
      ENV.delete ENVIRONMENT_VARIABLE
      FileUtils.remove_entry_secure uid_file if @workspace and File.exists?(uid_file)
    end

    private

    def save_uid uid
      FileUtils.mkdir_p File.dirname(uid_file)
      File.open(uid_file, 'w'){ |f| f.write uid }
    end

    def env_var
      ENV[ENVIRONMENT_VARIABLE]
    end

    def current_uid
      File.file?(uid_file) ? File.read(uid_file) : nil
    end

    def uid_file
      @uid_file ||= File.join(@workspace, 'uid')
    end

    def generate_uid
      "#{Time.now.utc.strftime '%Y%m%d%H%M%S'}-#{SecureRandom.uuid}"
    end
  end
end
