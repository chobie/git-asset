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
end