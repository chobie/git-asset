module GitAsset
  module Transport

    # Local Transport
    #
    # configurations
    #
    # [git-asset]
    #    transport = local
    #
    # [git-asset.transport.local]
    #    path = /tmp/assets
    #
    class Local < Base
      def validate()
        raise "git-asset.transport section does not find" if config["git-asset"]["transport"].nil?
        raise "git-asset.transport.local section does not find" if config["git-asset"]["transport"]["local"].nil?
        raise "path does not set" if config["git-asset"]["transport"]["local"]["path"].nil?
      end

      def exists?(path)
        File.exists?(real_asset_path(path))
      end

      def push(path, file_path)
        if !exists?(path)
          asset_path = real_asset_path(path)

          tempfile = Tempfile.new('asset')
          open(file_path, "rb"){|f|
            while data = f.read(8192)
              tempfile.write data
            end
            tempfile.close
          }

          FileUtils.mkdir_p(File.dirname(asset_path)) unless File.directory? File.dirname(asset_path)
          FileUtils.mv(tempfile.path, asset_path)
        end
      end

      def pull(path)
        if exists?(path)
          asset_path = real_asset_path(path)

          open(asset_path, "r") do |f|
            tempfile = Tempfile.new('asset')
            while data = f.read(8192)
              tempfile.write data
            end

            tempfile.close

            STDERR.puts "copying file."
            FileUtils.mkdir_p(File.join(@gitdir, "/asset/objects",  path[0,2]))
            FileUtils.mv(tempfile.path, File.join(@gitdir, "/asset/objects",  path[0,2], path[2,40]))
          end
        else
          STDERR.puts "NAIPOOO:" + real_asset_path(path)
        end
      end

      protected
      def real_asset_path(path)
        File.join(config["git-asset"]["transport"]["local"]["path"], path[0,2], path[2,40])
      end
    end
  end
end