require 'aws-sdk-s3'

module Dev
  class Aws
    # Class for performing S3 functions
    class S3
      attr_reader :client

      def initialize
        @client = nil
      end

      # Create/set a new client if none is present
      # Return the client
      def client
        @client ||= ::Aws::S3::Client.new
      end

      # Puts the local filename into the given bucket named as the given key
      # Optionally specify an acl. defaults to 'private'
      # Returns the URL of the uploaded file
      def put(bucket:, key:, filename:, acl: 'private')
        begin
          File.open(filename, 'rb') do |file|
            client.put_object(bucket: bucket, key: key, body: file, acl: acl)
          end
        rescue => e
          raise "s3 file upload failed: #{e.message}"
        end

        url = "https://#{bucket}.s3.#{Dev::Aws::Credentials.new.logged_in_region}.amazonaws.com/#{key}"
        LOG.info "Uploaded #{url}"
        url
      end

      # Finds the specific name of the appropriate "cf-templates-" bucket to use to upload cloudformation templates to
      def cf_bucket
        client.list_buckets.buckets.find { |bucket| bucket.name.match(/^cf-templates-.*-#{Dev::Aws::Credentials.new.logged_in_region}/) }
      end
    end
  end
end
