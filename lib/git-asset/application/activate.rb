module GitAsset
  module Application
    class Activate
      def self.run!
        `git config filter.asset.smudge "git-asset filter-smudge %f"`
        `git config filter.asset.clean "git-asset filter-clean %f"`
   end
    end
  end
end