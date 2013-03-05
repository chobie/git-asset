require 'hashie'

module GitAsset
  class ConfigParser
    def parsed
      @config
    end

    def initialize(contents)
      lines = []
      # preformat contents
      contents.split(/\r?\n/).each do |line|
        if line[0] == '#' || line[0] == ';'
          next
        end

        line = line.sub(/^\s+/, "").sub(/\s+$/, "")

        if line.empty?
          next
        end

        if line[0] == "["
          line = line.gsub(/["']/, '').gsub(/\s+/, ".")
        else
          key, value = line.split(/=/, 2)

          key.sub!(/\s+$/, "")
          value = value.sub(/^\s+/, "").sub(/^\s+$/, "").sub(/^['"]/, '').sub(/['"]$/, '')

          line = sprintf("%s=%s", key, value)
        end

        lines.push line
      end

      # parse config
      result = {}
      subhash = nil
      current_key = nil

      lines.each do |line|
        if line[0] == "["
          line = line.gsub(/(\[|\])/, "")
          subkeys = line.split(".")
          subhash = subkeys.inject(result) do |hash, k|
            if !hash.has_key?(k)
              hash[k] = {}
            end
            hash[k]
          end
        else
          key, value = line.split("=", 2)
          if subhash
            subhash[key] = value
          end
        end
      end

      @config = Hashie::Mash.new(result)
    end
  end
end
