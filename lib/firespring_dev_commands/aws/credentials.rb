require 'aws-sdk-sts'
require 'aws-sdk-ssm'
require 'inifile'
require 'json'
require 'net/http'

module Dev
  class Aws
    # Class contains methods for interacting with your Aws credentials
    class Credentials
      # The local file where temporary credentials are stored
      CONFIG_FILE = "#{Dev::Aws::CONFIG_DIR}/credentials".freeze

      def self.config_ini
        IniFile.new(filename: CONFIG_FILE, default: 'default')
      end

      # The account the profile is currently logged in to
      def logged_in_account
        ::Aws::STS::Client.new.get_caller_identity.account
      end

      # The arn of the currently logged in identity
      def logged_in_arn
        ::Aws::STS::Client.new.get_caller_identity.arn
      end

      # The role the current identity is using
      def logged_in_role
        logged_in_arn.split(%r{/})[1]
      end

      # The region associated with the current login
      def logged_in_region
        ::Aws::STS::Client.new.send(:config).region
      end

      # Whether or not the current credentials are still active
      def active?(profile = Dev::Aws::Profile.new.current)
        # If there is a metadata uri then we are in an AWS env - assume we are good
        return true if ENV.fetch('ECS_CONTAINER_METADATA_URI', nil)

        # Otherwise there should either be an aws config directory or access key configured
        return false unless File.exist?(Dev::Aws::CONFIG_DIR) || ENV.fetch('AWS_ACCESS_KEY_ID', nil)

        # TODO: I'd prefer to still validate creds if using a METADATA_URI
        # However this appears to require additional permissions which might not be present. Is there a better check here?
        # return false if !ENV.fetch('ECS_CONTAINER_METADATA_URI', nil) && !(File.exist?(Dev::Aws::CONFIG_DIR) || ENV.fetch('AWS_ACCESS_KEY_ID', nil))

        # Check for expired credentials
        begin
          ::Aws::STS::Client.new(profile: profile).get_caller_identity
        rescue
          return false
        end

        # Check for invalid credentials
        begin
          # TODO: Is there a better check we can do here?
          ::Aws::SSM::Client.new(profile: profile).describe_parameters(max_results: 1)
        rescue
          return false
        end

        # If the credentials are valid, make sure they are set in the ruby process environment for use later
        export!
        true
      end

      # Setup base Aws credential settings
      def base_setup!
        # Make the base config directory
        FileUtils.mkdir_p(Dev::Aws::CONFIG_DIR)

        puts
        puts 'Configuring default credential values'

        # Write access key / secret key in the credentials file
        credini = self.class.config_ini
        defaultini = credini['default']

        access_key_default = defaultini['aws_access_key_id']
        defaultini['aws_access_key_id'] = Dev::Common.new.ask('AWS Access Key ID', access_key_default)

        secret_key_default = defaultini['aws_secret_access_key']
        defaultini['aws_secret_access_key'] = Dev::Common.new.ask('AWS Secret Access Key', secret_key_default)

        credini.write
      end

      # Write Aws account specific settings to the credentials file
      def write!(account, creds)
        # Write access key / secret key / session token in the credentials file
        credini = self.class.config_ini
        defaultini = credini[account]

        defaultini['aws_access_key_id'] = creds.access_key_id
        defaultini['aws_secret_access_key'] = creds.secret_access_key
        defaultini['aws_session_token'] = creds.session_token

        credini.write
      end

      # Export our current credentials into the ruby environment
      def export!
        export_profile_credentials!
        export_container_credentials!
      end

      # Exports the credentials if there is an active credentials uri
      def export_container_credentials!
        # If we already have creds defined, don't do anything
        return if ENV.fetch('AWS_ACCESS_KEY_ID', nil)

        # If a container credentials url is not present, don't do anything
        ecs_creds = ENV.fetch('AWS_CONTAINER_CREDENTIALS_RELATIVE_URI', nil)
        return unless ecs_creds

        # Otherwise query the local creds, parse the json response, and store in the environment
        response = Net::HTTP.get_response(URI.parse("http://169.254.170.2#{ecs_creds}"))
        raise 'Error getting container credentials' unless response.is_a?(Net::HTTPSuccess)

        creds = JSON.parse(response.body)
        ENV['AWS_ACCESS_KEY_ID'] = creds['AccessKeyId']
        ENV['AWS_SECRET_ACCESS_KEY'] = creds['SecretAccessKey']
        ENV['AWS_SESSION_TOKEN'] = creds['Token']
        ENV['AWS_DEFAULT_REGION'] = logged_in_region
      end

      # Exports the credentials if there is a configured aws profile
      def export_profile_credentials!
        # If we already have creds defined, don't do anything
        return if ENV.fetch('AWS_ACCESS_KEY_ID', nil)

        # If a profile config file is not present, don't do anything
        return unless File.exist?(CONFIG_FILE)

        # Otherwise load access key / secret key / session token from the credentials file into the environment
        credini = self.class.config_ini
        profile_credentials = credini[Dev::Aws::Profile.new.current]
        return unless profile_credentials

        ENV['AWS_ACCESS_KEY_ID'] = profile_credentials['aws_access_key_id']
        ENV['AWS_SECRET_ACCESS_KEY'] = profile_credentials['aws_secret_access_key']
        ENV['AWS_SESSION_TOKEN'] = profile_credentials['aws_session_token']
        ENV['AWS_DEFAULT_REGION'] = logged_in_region
      end
    end
  end
end
