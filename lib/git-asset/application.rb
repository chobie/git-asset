require 'git-asset/application/activate'
require 'git-asset/application/deactivate'

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
        GitAsset::Application::Deactivate.run!
      when "activate"
        puts "# activate assets."
        GitAsset::Application::Activate.run!
      when "sync"
        `git config filter.asset.smudge "git-asset-smudge %f"`
        `git config filter.asset.smudge "git-asset filter-smudge %f"`
        `git config filter.asset.clean "git-asset filter-clean %f"`
        GitAsset::Application::Sync.run!
      when "filter-clean"
        # move file to asset path.
        Filter::Clean.run! ARGV.shift
      when "clean-repository"
        # move file to asset path.
        #`git config --remove-section filter.asset`
        Filter::Clean2.run!
        return 0
      when "filter-smudge"
        # move file from asset path.
        Filter::Smudge.run! ARGV.shift
      else
        print <<EOF
usage: git asset
                 activate    activate filter
                 deactivate  deactivate filter
                 sync        activate filter and checkout files
EOF
      end
    end

  end
end