module GitAsset
  module Filter
    class Clean
      def self.run!(path)
        STDERR.puts "# Clean: " + path + "\n"

        git_dir    = GitCommand.toplevel
        #STDERR.puts asset_path

        hashfunc = Digest::SHA1.new
        tempfile = Tempfile.new('asset')

        # required
        bytes = 0
        while data = STDIN.read(4096)
          hashfunc.update data
          bytes += tempfile.write(data)
        end

        #STDERR.puts(sprintf("bytes: %d\n", bytes))
        if bytes == 41
          raise "something wrong? (probably this is a bug for git-asset)"
        end
        tempfile.close

        STDOUT.print hx = hashfunc.hexdigest
        STDOUT.binmode
        STDOUT.write("\n")

        asset_path = File.join(GitCommand.toplevel, GitCommand.asset_path, hx[0,2], hx[2,40])
        asset_dir  = File.dirname asset_path
        FileUtils.mkdir_p(asset_dir) unless File.directory? asset_dir

        if File.exists? asset_path
          if Digest::SHA1.hexdigest(File.open(asset_path, "rb").read) != hx
            FileUtils.mv(tempfile.path, asset_path)
          end
        else
          FileUtils.mv(tempfile.path, asset_path)
        end

        transport = GitAsset::Transport::Local.new({:path => "/tmp/assets"})
        if !transport.exists?(hx.to_s)
          transport.push(hx.to_s, asset_path)
        end

      end
    end
  end
end