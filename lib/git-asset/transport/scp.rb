require 'git-asset/transport'

module GitAsset
  module Transport

    # git-asset.transport.type = scp
    # git-asset.transport.scp.user someuser
    # git-asset.transport.scp.host remoteserver.com
    # git-asset.transport.scp.path /opt/media
    # git-asset.transport.scp.port 22
    # git-asset.transport.scp.opts -l 8000
    class Scp < Base
      def initialize(gitdir, config)
        super(gitdir, config)

        @user = config["git-asset"]["transport"]["scp"]["user"] || ENV["USER"]
        @host = config["git-asset"]["transport"]["scp"]["host"]
        @port = config["git-asset"]["transport"]["scp"]["port"] || 22
        @opts = config["git-asset"]["transport"]["scp"]["opts"]
        @push_path = config["git-asset"]["transport"]["scp"]["path"]
      end

      def validate()
        raise "git-asset.transport section does not find" if config["git-asset"]["transport"].nil?
        raise "git-asset.transport.scp section does not find" if config["git-asset"]["transport"]["scp"].nil?
        raise "path does not set" if config["git-asset"]["transport"]["scp"]["path"].nil?
        raise "host does not set" if config["git-asset"]["transport"]["scp"]["host"].nil?
      end

      def exists?(path)
        file = File.join(@push_path, path)
        if `ssh #{@user}@#{@host} -p #{@port} [ -f "#{file}" ] && echo 1 || echo 0`.chomp == "1"
          STDERR.puts "exists"
          return true
        else
          STDERR.puts "does not exist"
          return false
        end
      end

      def pull(path)
        File.join(config["git-asset"]["transport"]["local"]["path"], path[0,2], path[2,40])
        asset_path = File.join(gitdir, "/asset/object")
        FileUtils.mkdir_p(File.dirname(asset_path)) unless File.directory? File.dirname(asset_path)
        STDERR.puts "scp -P #{@port} #{@opts} #{@user}@#{@host}:#{@push_path}/#{path} #{gitdir}/asset/objects/#{path[0,2]}/#{path[2,40]}"
        `scp -P #{@port} #{@opts} #{@user}@#{@host}:#{@push_path}/#{path} #{gitdir}/asset/objects/#{path[0,2]}/#{path[2,40]}`

        if $? == 0
          STDERR.puts "downloaded #{path}"
        else
          STDERR.puts "can't download #{path}"
        end
      end

      def push(path, data)
        STDERR.puts "scp -P #{@port} #{@opts} #{data} #{@user}@#{@host}:#{@push_path}/#{path}"
        `scp -P #{@port} #{@opts} #{data} #{@user}@#{@host}:#{@push_path}/#{path}`
      end

    end
  end
end