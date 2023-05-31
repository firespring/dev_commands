require 'aws-sdk-ecr'
require 'aws-sdk-sts'
require 'inifile'

module Dev
  class Aws
    # Class containing methods for helping a user log in to aws
    class Login
      # Main interface for logging in to an AWS account
      # If an account is not specified the user is given an account selection menu
      # If account registries have been configured, the user is also logged in to the docker registries
      def login!(account = nil)
        # If more than one child account has been configured, have the user select the account they want to log in to
        account ||= Dev::Aws::Account.new.select

        # Authorize if our creds are not active
        authorize!(account) unless Dev::Aws::Credentials.new.active?(account)

        # Ensure the local env is pointed to the profile we selected
        Dev::Aws::Profile.new.write!(account)

        # Load credentials into the ENV for subprocesses
        Dev::Aws::Credentials.new.export!

        # Login in to all configured docker registries
        registry_logins!
      end

      # Authorize your local credentials
      # User is prompted for an MFA code
      # Temporary credentials are written back to the credentials file
      def authorize!(account)
        # Make sure the account has been set up
        cfgini = setup_cfgini(account)

        defaultini = cfgini['default']
        profileini = cfgini["profile #{account}"]

        region = profileini['region'] || defaultini['region'] || Dev::Aws::DEFAULT_REGION

        serial = profileini['mfa_serial_name'] || defaultini['mfa_serial_name']
        serial = "arn:aws:iam::#{Dev::Aws::Account.new.root.id}:mfa/#{serial}" if serial
        serial ||= profileini['mfa_serial'] || defaultini['mfa_serial']

        role = profileini['role_name'] || defaultini['role_name']
        role = "arn:aws:iam::#{account}:role/#{role}" if role
        role ||= profileini['role_arn'] || defaultini['role_arn']

        session_name = profileini['role_session_name'] || defaultini['role_session_name']
        session_duration = profileini['session_duration'] || defaultini['session_duration']

        puts
        puts "  Logging in to #{account} in #{region} as #{role}".light_yellow
        puts

        code = ENV['AWS_TOKEN_CODE'] || Dev::Common.new.ask("Enter the MFA code for the #{ENV.fetch('USERNAME', '')} user serial #{serial}")
        raise 'MFA is required' unless code.to_s.strip

        sts = ::Aws::STS::Client.new(profile: 'default', region: region)
        creds = sts.assume_role(
          serial_number: serial,
          role_arn: role,
          role_session_name: session_name,
          token_code: code,
          duration_seconds: session_duration
        ).credentials
        puts

        Dev::Aws::Credentials.new.write!(account, creds)
      end

      # Returns the config ini file
      # Runs the setup for our current account if it's not already setup
      def setup_cfgini(account)
        cfgini = IniFile.new(filename: "#{Dev::Aws::CONFIG_DIR}/config", default: 'default')
        unless cfgini.has_section?("profile #{account}")
          Dev::Aws::Account.new.write!(account)
          cfgini = IniFile.new(filename: "#{Dev::Aws::CONFIG_DIR}/config", default: 'default')
        end
        cfgini
      end

      # Authroizes the docker cli to pull/push images from the Aws container registry (e.g. if docker compose needs to pull an image)
      # Authroizes the docker ruby library to pull/push images from the Aws container registry
      def registry_logins!(registry_ids: nil, region: nil)
        registry_ids ||= Dev::Aws::Account.new.ecr_registry_ids
        region ||= Dev::Aws::Credentials.new.logged_in_region || Dev::Aws::DEFAULT_REGION
        return if registry_ids.empty?

        puts
        registry_ids.each { |id| registry_login!(registry_id: id, region: region) }
        puts
      end

      # Authroizes the docker cli to pull/push images from the Aws container registry (e.g. if docker compose needs to pull an image)
      # Authroizes the docker ruby library to pull/push images from the Aws container registry
      def registry_login!(registry_id: nil, region: nil)
        registry_id ||= Dev::Aws::Account.new.ecr_registry_ids.first
        region ||= Dev::Aws::Credentials.new.logged_in_region || Dev::Aws::DEFAULT_REGION
        raise 'registry_id is required' if registry_id.to_s.strip.empty?
        raise 'region is required' if region.to_s.strip.empty?

        registry = "#{registry_id}.dkr.ecr.#{region}.amazonaws.com"
        docker_cli_login!(registry: registry, region: region)
        docker_lib_login!(registry_id: registry_id, region: region)

        ENV['ECR_REGISTRY_ID'] ||= registry_id
        ENV['ECR_REGISTRY'] ||= registry
      end

      # Authroizes the docker cli to pull/push images from the Aws container registry
      # (e.g. if docker compose needs to pull an image)
      # @deprecated Please use {Dev::Aws::Login#registry_login!} instead
      def docker_login!(registry_id: nil, region: nil)
        registry_id ||= Dev::Aws::Account.new.ecr_registry_ids.first
        region ||= Dev::Aws::Credentials.new.logged_in_region || Dev::Aws::DEFAULT_REGION
        warn '[DEPRECATION] `Dev::Aws::Login#docker_login!` is deprecated. Please use `Dev::Aws::Login#registry_login!` instead.'
        docker_cli_login!(registry: "#{registry_id}.dkr.ecr.#{region}.amazonaws.com", region: region)
        puts
      end

      # Authroizes the docker cli to pull/push images from the Aws container registry
      # (e.g. if docker compose needs to pull an image)
      private def docker_cli_login!(registry:, region:)
        print("  Logging in to #{registry} in docker... ")
        login_cmd = "aws --profile=#{Dev::Aws::Profile.new.current} ecr --region=#{region} get-login-password"
        login_cmd << ' | '
        login_cmd << "docker login --password-stdin --username AWS #{registry}"
        Dev::Common.new.run_command([login_cmd])
      end

      # Authroizes the docker ruby library to pull/push images from the Aws container registry
      # @deprecated Please use {Dev::Aws::Login#registry_login!} instead
      def ecr_login!(registry_id: nil, region: nil)
        registry_id ||= Dev::Aws::Account.new.ecr_registry_ids.first
        region ||= Dev::Aws::Credentials.new.logged_in_region || Dev::Aws::DEFAULT_REGION
        warn '[DEPRECATION] `Dev::Aws::Login#ecr_login!` is deprecated. Please use `Dev::Aws::Login#registry_login!` instead.'
        docker_lib_login!(registry_id: registry_id, region: region)
      end

      # Authroizes the docker ruby library to pull/push images from the Aws container registry
      private def docker_lib_login!(registry_id:, region:)
        # Grab your authentication token from AWS ECR
        ecr_client = ::Aws::ECR::Client.new(region: region)
        tokens = ecr_client.get_authorization_token(registry_ids: Array(registry_id)).authorization_data
        tokens.each do |token|
          # Remove the https:// to authenticate
          repo_url = token.proxy_endpoint.gsub('https://', '')

          # Authorization token is given as username:password, split it out
          user_pass_token = Base64.decode64(token.authorization_token).split(':')

          # Call the authenticate method with the options
          ::Docker.authenticate!(
            username: user_pass_token.first,
            password: user_pass_token.last,
            email: 'none',
            serveraddress: repo_url
          )
        end
      end
    end
  end
end
