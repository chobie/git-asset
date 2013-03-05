module GitAsset
  module Application
    class Deactivate
      def self.run!
        `git config --remove-section filter.asset`
        filter = []
        GitAsset::Filter::GitCommand.attributes.each do |val|
          filter.push(val[:pattern]) if val[:filter].include?("asset")
        end

        result = []
        GitAsset::Filter::GitCommand.targets() do |obj|
          filter.each do |f|
            if File.fnmatch?(f, obj[:name].downcase)
              result.push(obj)
            end
          end
        end

        result.each do |obj|
          `git checkout -qf HEAD -- #{obj[:path]}`
        end

      end
    end
  end
end