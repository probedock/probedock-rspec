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

      data = options[:data]
      metadata = example.metadata

      # TODO: remove once Probe Dock has been migrated to use fingerprints
      data['fingerprint'] = options[:fingerprint]

      data['file.path'] = metadata[:file_path].to_s.sub(/^\.\//, '') if metadata[:file_path]
      data['file.line'] = metadata[:line_number] if metadata[:line_number]

      options
    end

    private

    def self.extract_key example, groups = []
      (groups.collect{ |g| probedock_meta(g)[:key] } << probedock_meta(example)[:key]).compact.reject{ |k| k.strip.empty? }.last
    end

    def self.probedock_meta holder

      meta = holder.metadata[:probedock] || {}

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
      cat = (groups.collect{ |g| probedock_meta(g)[:category] } << probedock_meta(example)[:category]).compact.last
      cat ? cat.to_s : nil
    end

    def self.extract_tags example, groups = []
      (groups.collect{ |g| wrap probedock_meta(g)[:tags] } + (wrap probedock_meta(example)[:tags])).flatten.compact.uniq.collect(&:to_s)
    end

    def self.extract_tickets example, groups = []
      (groups.collect{ |g| wrap probedock_meta(g)[:tickets] } + (wrap probedock_meta(example)[:tickets])).flatten.compact.uniq.collect(&:to_s)
    end

    def self.extract_data example, groups = []
      probedock_meta(example)[:data] || {}
    end

    def self.wrap a
      a.kind_of?(Array) ? a : [ a ]
    end
  end
end
