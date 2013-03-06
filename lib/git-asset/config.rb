require 'git-asset/config_parser'

module GitAsset
  class Config
    attr_reader :git_dir, :config

    def initialize
      puts "initalized"

      topdir = seek_topdir

      if topdir.nil?
        raise "can't find git directory."
      end

      @git_dir = topdir
      @config = parse_config
    end

    def self.instance
      @class ||= self.new
    end

    def self.parsed
      instance = self.instance
      instance.config
    end

    def parse_config
      config_path = File.join(git_dir, "config")
      if File.exist?(config_path)
        @config = ConfigParser.new(open(config_path, "r"){|f| f.read}).parsed
      else
        raise "can't find git config"
      end
    end

    def seek_topdir
      attempts = 0
      max_attempts = 20
      directory = Dir.pwd

      while attempts < max_attempts

        path = File.join(directory, ".git")
        if File.directory?(path)
          return path
        else
          directory = File.dirname(directory)
        end

        attempts += 1
      end

      return nil
    end
  end
end