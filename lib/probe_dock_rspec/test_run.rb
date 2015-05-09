
module ProbeDockRSpec

  class TestRun
    attr_reader :results, :project
    attr_accessor :duration, :uid

    def initialize project
      @results = []
      @project = project
    end

    def add_result example, groups = [], options = {}

      if TestResult.extract_grouped(example, groups) and (existing_result = @results.find{ |r| r.grouped? && r.key == TestResult.extract_key(example, groups) })
        existing_result.update options
      else
        @results << TestResult.new(@project, example, groups, options)
      end
    end

    def results_without_key
      @results.select{ |r| !r.key or r.key.to_s.strip.empty? }
    end

    def results_by_key
      @results.inject({}) do |memo,r|
        (memo[r.key] ||= []) << r unless !r.key or r.key.to_s.strip.empty?
        memo
      end
    end

    def to_h options = {}
      validate!

      {
        'projectId' => @project.api_id,
        'version' => @project.version,
        'duration' => @duration,
        'results' => @results.collect{ |r| r.to_h options }
      }.tap do |h|
        h['reports'] = [ { 'uid' => @uid } ] if @uid
      end
    end

    private

    def validate!
      # TODO: validate duration

      raise PayloadError.new("Missing project") if !@project
      @project.validate!

      # FIXME: log info/warnings
      #validate_no_results_without_key
      #validate_no_duplicate_keys
    end

    def validate_no_duplicate_keys

      results_with_duplicate_key = results_by_key.select{ |k,r| r.length >= 2 }
      return if results_with_duplicate_key.none?

      msg = "the following keys are used by multiple test results".tap do |s|
        results_with_duplicate_key.each_pair do |key,results|
          s << "\n     - #{key}"
          results.each{ |r| s << "\n       - #{r.name}" }
        end
      end

      raise PayloadError.new(msg)
    end

    def validate_no_results_without_key

      keyless = results_without_key
      return if keyless.empty?

      msg = "the following test results are missing a key".tap do |s|
        keyless.each{ |r| s << "\n     - #{r.name}" }
      end

      raise PayloadError.new(msg)
    end
  end
end
