require 'digest/sha1'

module ProbeDockRSpec
  class MetaParser

    def self.parse example, groups = []

      options = {}

      %i(key category tags tickets data).each do |attr|
        options[attr] = send "extract_#{attr}", example, groups
      end

      name_parts = extract_name_parts example, groups
      options[:name] = name_parts.join ' '
      options[:fingerprint] = Digest::SHA1.hexdigest name_parts.join('|||')

      # TODO: remove once Probe Dock has been migrated to use fingerprints
      options[:data][:fingerprint] = options[:fingerprint]

      options
    end

    private

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

    def self.extract_name_parts example, groups = []
      (groups.collect(&:description) << example.description).compact.collect(&:strip).reject{ |p| p.empty? }
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
