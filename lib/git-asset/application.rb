require 'git-asset/application/activate'
require 'git-asset/application/deactivate'
require 'git-asset/application/sync'

module GitAsset
  module Application
    def self.get_transport
      config = GitAsset::Config.parsed
      raise "git-asset section does not find." if config["git-asset"].nil?

      transport = case config["git-asset"].transport.primary
        when "local"
          GitAsset::Transport::Local.new(GitAsset::Config.instance.git_dir, config)
        when "scp"
          GitAsset::Transport::Scp.new(GitAsset::Config.instance.git_dir, config)
        when "s3"
          GitAsset::Transport::S3.new(GitAsset::Config.instance.git_dir, config)
        else
          raise "git-asset.transport does not find"
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