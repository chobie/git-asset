require 'fileutils'
require 'tempfile'
require 'digest/sha1'
require 'pp'

module GitAsset
  module Application
    def self.prepare
      asset_path = `git config git-asset.path`.chomp
      if asset_path.empty?
        puts "# git-asset failed\nyou have to do `git config git-asset.path 'assets'` before run asset command"
        exit -1
      end
    end

    def self.run!
      cmd = ARGV.shift
      cmd_opts = case cmd
        when "deactivate"
          puts "# deactivate assets."
          `git config --remove-section filter.asset`
          filter = []
          Filter::GitCommand.attributes.each do |val|
            filter.push(val[:pattern]) if val[:filter].include?("asset")
          end

          result = []
          Filter::GitCommand.targets() do |obj|
            filter.each do |f|
              if File.fnmatch?(f, obj[:name].downcase)
                result.push(obj)
              end
            end
          end

          result.each do |obj|
            `git checkout -qf HEAD -- #{obj[:path]}`
          end
        when "activate"
          `git config filter.asset.smudge "git-asset filter-smudge %f"`
          `git config filter.asset.clean "git-asset filter-clean %f"`
        when "sync"
          # do svn add, commit or svn update
          #`git config filter.asset.smudge "git-asset-smudge %f"`
          `git config filter.asset.smudge "git-asset filter-smudge %f"`
          `git config filter.asset.clean "git-asset filter-clean %f"`

          Sync.run!
        when "filter-clean"
          # move file to asset path.
          Filter::Clean.run! ARGV.shift
        when "clean-repository"
          # move file to asset path.
          #`git config --remove-section filter.asset`
          puts "# Clean2"
          Filter::Clean2.run!
          return 0
        when "filter-smudge"
          # move file from asset path.
          Filter::Smudge.run! ARGV.shift
        when "config:example"
          # do svn add, commit or svn update
          puts <<EOF
git config git-asset.path "assets"

# before add / checkout
git config filter.asset.smudge "git-asset filter-smudge %f"
git config filter.asset.clean "git-asset filter-clean %f"
EOF
        when "debug"
          GitAsset::Application.prepare

          # move file from asset path.
          filter = []
          Filter::GitCommand.attributes.each do |val|
            filter.push(val[:pattern]) if val[:filter].include?("asset")
          end

          raise "filter does not set." if filter.empty?

          result = []
          Filter::GitCommand.targets() do |obj|
            filter.each do |f|
              if File.fnmatch?(f, obj[:name])
                result.push(obj)
              end
            end
          end

          asset_dir = File.join(Filter::GitCommand.toplevel, Filter::GitCommand.asset_path)
          puts "# current assets status"
          # puts asset_dir
          result.each do |obj|
            status = case File.exist?(File.join(asset_dir, obj[:path]))
            when true
                "OK"
            when false
                "Crouppted"
            end

            puts sprintf("[%10s]\t%s\n", status, obj[:path])
          end
          exit
      else
        print <<EOF
usage: git asset (filter-clean|filter-smudge|sync) <PATH>

EOF
      end
    end
  end

  class Sync
    def self.run!
      GitAsset::Application.prepare

      puts "# running sync process..."

      # move file from asset path.
      filter = []
      Filter::GitCommand.attributes.each do |val|
        filter.push(val[:pattern]) if val[:filter].include?("asset")
      end

      result = []
      Filter::GitCommand.targets() do |obj|
        filter.each do |f|
          if File.fnmatch?(f, obj[:name].downcase)
            result.push(obj)
          end
        end
      end

      asset_dir = File.join(Filter::GitCommand.toplevel, Filter::GitCommand.asset_path)

      # puts asset_dir

      transport = GitAsset::Transport::Local.new({:path => "/tmp/assets"})

      result.each do |obj|
        target_path = File.join(File.dirname(Filter::GitCommand.toplevel), obj[:path])
        #asset_path  = File.join(Filter::GitCommand.toplevel, Filter::GitCommand.asset_path, data[0,2], data[2,40])

        if File.exists?(target_path)
          data = open(target_path, "rb").read(41)
          if data =~ /^[0-9a-f]{40}/
            #puts sprintf("syncing %s...", obj[:path])
            #FileUtils.copy(asset_path, target_path)
            data.chomp!

            if !File.exists?(File.join(asset_dir, data[0,2], data[2,40]))
              if transport.exists?(data)
                transport.pull(data)
              end

            end
            FileUtils.remove(obj[:path])
          else
            raise "DAMEPO. probably you've already sync'ed?"
          end
        else
          raise "something wrong"
        end
      end


      STDERR.puts "# okay, now update git-index"
      `git checkout -- .`
      #result.each do |obj|
      #  target_path = File.join(Filter::GitCommand.toplevel, obj[:path])
      #end
    end
  end

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

    class Clean2
      def self.run!
        # Todo:
        filter = ["*.png", "*.gif", "*.jpg", "*.tar.gz", "*.tar.bz2", "*.pdf", "*.jpeg", "*.zip", "*.swf", "*.mp3"]

        if !ENV.has_key?("GIT_COMMIT")
          raise "git asset clean-repository requires GIT_COMMIT env."
        end

        result = []
        Filter::GitCommand.targets2() do |obj|
          filter.each do |f|
            if obj[:type] == 'D'
              next
            end

            if File.fnmatch?(f, obj[:name].downcase)
              result.push(obj)
            end
          end
        end

        # puts asset_dir
        transport = GitAsset::Transport::Local.new({:path => "/tmp/assets"})

        result.each do |obj|
          target_path = File.join(obj[:path])

          puts target_path
          if File.exists?(target_path)
            line = ""
            open(target_path, "rb") do |f|
              line = f.read(40)
            end

            if !(line =~ /^[0-9a-f]{40}/)
              puts "# " + target_path
              sha1 = obj[:hash]
              if !transport.exists?(sha1)
                puts "push transport"
                transport.push(sha1, target_path)
              end

              open(target_path, "w") do |f|
                puts "writing sha1 to #{target_path}"
                f.write sha1
              end

            end
          else
            puts "Nothing to do."
          end
        end
      end
    end

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

  module Transport
    class Base
      attr_reader :config
      def initialize(config)
        @config = config
        validate
      end

      ### Overrides ###
      def exists?(path)
        return nil
      end

      def pull(path)
        return nil
      end

      def push(path, data)
        return nil
      end

      def validate()
      end
    end

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
