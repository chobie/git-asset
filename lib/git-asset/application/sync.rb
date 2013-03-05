module GitAsset
  module Application
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
  end
end