module GitAsset
  module Filter
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
        transport = GitAsset::Application.get_transport

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
  end
end