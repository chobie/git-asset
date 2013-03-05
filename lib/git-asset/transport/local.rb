module GitAsset
  module Transport

    class Local < Base
      def validate()
        if config[:path].nil?
          raise "path does not set"
        end
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
        p exists?(path)
        if exists?(path)
          asset_path = real_asset_path(path)

          open(asset_path, "r") do |f|
            tempfile = Tempfile.new('asset')
            while data = f.read(8192)
              tempfile.write data
            end

            tempfile.close
            puts "copying file."
            FileUtils.mkdir_p(File.join("/Users/chobie/src/asset-test/.git/asset/objects",  path[0,2]))
            FileUtils.mv(tempfile.path, File.join("/Users/chobie/src/asset-test/.git/asset/objects",  path[0,2], path[2,40]))
          end
        else
          puts "NAIPOOO:" + real_asset_path(path)
        end
      end

      protected
      def real_asset_path(path)
        File.join(config[:path], path[0,2], path[2,40])
      end
    end
  end
end