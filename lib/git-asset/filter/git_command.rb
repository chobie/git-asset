module GitAsset
  module Filter
    module GitCommand
      def self.toplevel
        git_dir = `git rev-parse --git-dir`.chomp
        FileUtils.mkdir_p(git_dir) unless File.directory? git_dir

        git_dir
      end

      def self.attributes
        path = `git rev-parse --show-toplevel`.chomp
        if File.exists?(File.join(path, ".gitattributes"))
          data = open(File.join(path, ".gitattributes"), "r") do |f|
            f.read
          end

          result = []
          data.split(/\r?\n/).each do |line|
            line.chomp!
            if line.size == 0
              next
            end

            args = line.split(/\s+/)

            pattern = args.shift

            tmp = {
                :pattern => pattern,
                :filter => []
            }
            args.each_with_index do |a, idx|
              if a.index("=")
                key, value = a.split("=", 2)
                tmp[:filter].push(value)
              end
            end

            result.push tmp
          end

          result
        else
          []
        end
      end

      def self.targets
        if ENV.fetch("GIT_COMMIT")
          target = ENV["GIT_COMMIT"]
        else
          target = "HEAD"
        end
        `git ls-tree -r #{target}`.chomp.split(/\r?\n/).each do |line|
          mode, type, sha1, path = line.split(/\s+/, 4)
          ext = File.extname(path)
          yield({:mode => mode,
                 :type => type,
                 :hash => sha1,
                 :path => path,
                 :basename => File.basename(path, ext),
                 :name => File.basename(path),
                 :ext => ext.sub(/^\./, ""),
          })
        end
      end

      def self.targets2()
        #git diff --raw --no-abbrev --no-renames $GIT_COMMIT^!

        if ENV.fetch("GIT_COMMIT")
          target = ENV["GIT_COMMIT"]
        else
          target = "HEAD"
        end

        `git ls-tree -r #{target}`.chomp.split(/\r?\n/).each do |line|
          mode, type, sha1, path = line.split(/\s+/, 4)
          ext = File.extname(path)
          yield({:mode => mode,
                 :type => type,
                 :hash => sha1,
                 :path => path,
                 :basename => File.basename(path, ext),
                 :name => File.basename(path),
                 :ext => ext.sub(/^\./, ""),
          })
        end

      end

      def self.asset_path
        File.join("asset", "objects")
      end
    end

  end
end