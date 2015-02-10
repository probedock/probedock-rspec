
module ProbeDockRSpec

  class TestResult
    attr_reader :key, :name, :category, :tags, :tickets, :data, :duration, :message

    def initialize project, example, groups = [], options = {}

      @category = project.category
      @tags = project.tags
      @tickets = project.tickets

      @grouped = extract_grouped example, groups

      [ :key, :name, :category, :tags, :tickets, :data ].each do |attr|
        instance_variable_set "@#{attr}".to_sym, send("extract_#{attr}".to_sym, example, groups)
      end

      @passed = !!options[:passed]
      @duration = options[:duration]
      @message = options[:message]
    end

    def passed?
      @passed
    end

    def grouped?
      @grouped
    end

    def update options = {}
      @passed &&= options[:passed]
      @duration += options[:duration]
      @message = [ @message, options[:message] ].select{ |m| m }.join("\n\n") if options[:message]
    end

    def to_h options = {}
      {
        'k' => @key,
        'p' => @passed,
        'd' => @duration
      }.tap do |h|

        h['m'] = @message if @message

        cache = options[:cache]
        first = !cache || !cache.known?(self)
        stale = !first && cache.stale?(self)
        h['n'] = @name if stale or first
        h['c'] = @category if stale or (first and @category)
        h['g'] = @tags if stale or (first and !@tags.empty?)
        h['t'] = @tickets if stale or (first and !@tickets.empty?)
        h['a'] = @data if @data # FIXME: cache custom data
      end
    end

    def self.extract_grouped example, groups = []
      !!groups.collect{ |g| meta(g)[:grouped] }.compact.last
    end

    def self.extract_key example, groups = []
      (groups.collect{ |g| meta(g)[:key] } << meta(example)[:key]).compact.last
    end

    def self.meta holder
      meta = holder.metadata[:probe_dock] || {}
      if meta.kind_of? String
        { key: meta }
      elsif meta.kind_of? Hash
        meta
      else
        {}
      end
    end

    private

    def meta *args
      self.class.meta *args
    end

    def extract_grouped *args
      self.class.extract_grouped *args
    end

    def extract_key *args
      self.class.extract_key *args
    end

    def extract_name example, groups = []
      parts = groups.dup
      parts = parts[0, parts.index{ |p| meta(p)[:grouped] } + 1] if @grouped
      parts << example unless @grouped
      parts.collect{ |p| p.description.strip }.join ' '
    end

    def extract_category example, groups = []
      cat = (groups.collect{ |g| meta(g)[:category] }.unshift(@category) << meta(example)[:category]).compact.last
      cat ? cat.to_s : nil
    end

    def extract_tags example, groups = []
      (wrap(@tags) + groups.collect{ |g| wrap meta(g)[:tags] } + (wrap meta(example)[:tags])).flatten.compact.uniq.collect(&:to_s)
    end

    def extract_tickets example, groups = []
      (wrap(@tickets) + groups.collect{ |g| wrap meta(g)[:tickets] } + (wrap meta(example)[:tickets])).flatten.compact.uniq.collect(&:to_s)
    end

    def extract_data example, groups = []
      meta(example)[:data]
    end

    def wrap a
      a.kind_of?(Array) ? a : [ a ]
    end
  end
end
