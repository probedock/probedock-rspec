require 'digest/sha1'

module ProbeDockRSpec
  class MetaParser

    def self.parse example, groups = []

      options = {}

      %i(key category tags tickets data).each do |attr|
        options[attr] = send "extract_#{attr}", example, groups
      end

      grouped = extract_grouped example, groups
      options[:grouped] = !!grouped

      name_parts = extract_name_parts example, groups, grouped
      options[:name] = name_parts.join ' '
      options[:fingerprint] = Digest::SHA1.hexdigest name_parts.join('|||')
      options[:data][:fingerprint] = options[:fingerprint]

      options
    end

    private

    def self.extract_grouped example, groups = []
      !!groups.collect{ |g| meta(g)[:grouped] }.compact.last
    end

    def self.extract_key example, groups = []
      (groups.collect{ |g| meta(g)[:key] } << meta(example)[:key]).compact.reject{ |k| k.strip.empty? }.last
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

    def self.extract_name_parts example, groups = [], grouped = false
      parts = groups.dup
      parts = parts[0, parts.index{ |p| meta(p)[:grouped] } + 1] if grouped
      parts << example unless grouped
      parts.collect{ |p| p.description.strip }
    end

    def self.extract_category example, groups = []
      cat = (groups.collect{ |g| meta(g)[:category] } << meta(example)[:category]).compact.last
      cat ? cat.to_s : nil
    end

    def self.extract_tags example, groups = []
      (groups.collect{ |g| wrap meta(g)[:tags] } + (wrap meta(example)[:tags])).flatten.compact.uniq.collect(&:to_s)
    end

    def self.extract_tickets example, groups = []
      (groups.collect{ |g| wrap meta(g)[:tickets] } + (wrap meta(example)[:tickets])).flatten.compact.uniq.collect(&:to_s)
    end

    def self.extract_data example, groups = []
      meta(example)[:data] || {}
    end

    def self.wrap a
      a.kind_of?(Array) ? a : [ a ]
    end
  end
end
