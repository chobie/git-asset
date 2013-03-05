require 'git-asset/transport'
require 'aws-sdk'

module GitAsset
  module Transport

    # Local Transport
    #
    # configurations
    #
    # [git-asset]
    #    transport = s3
    #
    # [git-asset.transport.s3]
    #    key    = S3KEY
    #    secret = S3SECRET
    #    bucket = BucketName
    #
    #
    class S3 < Base
      def initialize(gitdir, config)
        super(gitdir, config)

        @s3_key = config["git-asset"]["transport"]["s3"]["key"]
        @s3_secret = config["git-asset"]["transport"]["s3"]["secret"]
        @s3_bucket = config["git-asset"]["transport"]["s3"]["bucket"]
      end

      def validate()
        raise "git-asset.transport section does not find" if config["git-asset"]["transport"].nil?
        raise "git-asset.transport.local section does not find" if config["git-asset"]["transport"]["s3"].nil?
        raise "key does not set" if config["git-asset"]["transport"]["s3"]["key"].nil?
        raise "secret does not set" if config["git-asset"]["transport"]["s3"]["secret"].nil?
        raise "bucket does not set" if config["git-asset"]["transport"]["s3"]["bucket"].nil?
      end

      def exists?(path)
        object = s3client.buckets[@s3_bucket].objects[path]
        object.exists?()
      end

      def push(path, file_path)
        if !exists?(path)
          object = s3client.buckets[@s3_bucket].objects[path]
          object.write(:file => file_path)
        end
      end

      def pull(path)
        if exists?(path)
          FileUtils.mkdir_p(File.join(@gitdir, "/asset/objects",  path[0,2]))
          File.open(File.join(@gitdir, "/asset/objects",  path[0,2], path[2,40]), 'w') do |file|
            s3client.buckets[@s3_bucket].objects[path].read do |chunk|
              file.write(chunk)
            end
          end
        else
          STDERR.puts "NAIPOOO:"
        end
      end

      protected
      def s3client
        @client ||= AWS::S3.new(
            :access_key_id => config["git-asset"]["transport"]["s3"]["key"],
            :secret_access_key => config["git-asset"]["transport"]["s3"]["secret"],
            :s3_endpoint => (config["git-asset"]["transport"]["s3"]["endpoint"] || "s3.amazonaws.com")
        )
      end

      def real_asset_path(path)
        File.join(config["git-asset"]["transport"]["local"]["path"], path[0,2], path[2,40])
      end
    end
  end
end