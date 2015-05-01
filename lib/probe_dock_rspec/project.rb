
module ProbeDockRSpec

  class Project
    attr_accessor :version, :api_id, :category, :tags, :tickets

    def initialize options = {}
      update options
    end

    def update options = {}
      %w(version api_id category).each do |k|
        instance_variable_set "@#{k}", options[k.to_sym] ? options[k.to_sym].to_s : nil if options.key? k.to_sym
      end
      @tags = wrap(options[:tags]).compact if options.key? :tags
      @tickets = wrap(options[:tickets]).compact if options.key? :tickets
    end

    def validate!
      required = { "version" => @version, "API identifier" => @api_id }
      missing = required.inject([]){ |memo,(k,v)| v.to_s.strip.length <= 0 ? memo << k : memo }
      raise PayloadError.new("Missing project options: #{missing.join ', '}") if missing.any?
    end

    private

    def wrap a
      a.kind_of?(Array) ? a : [ a ]
    end
  end
end
