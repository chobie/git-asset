module GitAsset
  module Filter
    class Smudge
      def self.run!(path)
        # Todo: これで実行初期か継続中かは分かる
        STDERR.puts "# Smudged: " + path + ":"
        #+ Process.ppid.to_s

        line = STDIN.readline(64).strip
        #raise "Can't fetch #{path}#" unless File.exist? asset_path

        STDOUT.binmode
        if line.size == 40
          git_dir        = GitCommand.toplevel
          git_asset_path = GitCommand.asset_path
          asset_path     = File.join(git_dir, git_asset_path, line[0,2], line[2,40])

          if File.exists? asset_path
            open(asset_path, "r") do |f|
              while data = f.read(8192)
                STDOUT.write data
              end
            end
          else
            STDERR.puts "# file does not exist. for now outputs stub file."
            while data = STDIN.read(8192)
              STDOUT.write data
            end
          end
        else
          STDERR.puts "# unexpected file size"
          while data = STDIN.read(8192)
            STDOUT.write data
          end
        end
      end
    end

  end
end