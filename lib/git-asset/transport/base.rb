module GitAsset
  module Transport
    class Base
      attr_reader :config, :gitdir
      def initialize(gitdir, config)
        @gitdir = gitdir
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
  end
end