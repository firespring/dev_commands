require_relative 'base_interface'

module Dev
  module Template
    # Class contains rake templates for managing your AWS settings and logging in
    class Aws < Dev::Template::BaseInterface
      # Create the rake task which ensures active credentials are present
      def create_ensure_credentials_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          return if exclude.include?(:ensure_aws_credentials)

          task ensure_aws_credentials: %w(init) do
            raise 'AWS Credentials not found / expired' unless Dev::Aws::Credentials.new.active?
          end
        end
      end

      # Create the rake task for the aws profile method
      def create_profile_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :aws do
            return if exclude.include?(:profile)

            desc 'Show the current profile/aws account you are configured to use'
            task profile: %w(init) do
              Dev::Aws::Profile.new.info
            end

            namespace :profile do
              desc 'Return the commands to export your AWS credentials into your environment'
              task :export do
                # Turn off all logging except for errors
                LOG.level = Logger::ERROR

                # Run the init
                Rake::Task[:init].invoke

                # Print the export info
                Dev::Aws::Profile.new.export_info
              end
            end
          end
        end
      end

      # rubocop:disable Metrics/MethodLength
      # Create the rake task for the aws credentials setup and login method
      def create_login_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :aws do
            return if exclude.include?(:login)

            namespace :configure do
              desc 'Configure the default AWS login settings'
              task default: %w(init default:credentials default:config) do
                puts
              end

              namespace :default do
                desc 'Configure the default AWS login credentials' \
                     "\n\t(primarily used for rotating access keys)"
                task credentials: %w(init) do
                  Dev::Aws::Credentials.new.base_setup!
                end

                task config: %w(init) do
                  Dev::Aws::Account.new.base_setup!
                end
              end

              Dev::Aws::Account.new.children.each do |account|
                desc "Configure the #{account.name} account login settings"
                task account.id => %w(init) do
                  Dev::Aws::Account.new.setup!(account.id)
                end
              end
            end

            desc 'Select the account you wish to log in to'
            task login: %w(init) do
              Dev::Aws::Login.new.login!
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      # Create the rake task for the eol method
      def create_eol_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          return if exclude.include?(:eol)
          return if ENV.fetch('CHECK_AWS', nil).to_s.strip == 'false'

          task eol: [:'eol:aws'] do
            # This is just a placeholder to execute the dependencies
          end

          namespace :eol do
            desc 'Compares the current date to the EOL date for supported aws resources'
            task aws: %w(init ensure_aws_credentials) do
              account_id = Dev::Aws::Profile.new.current
              account_name = Dev::Aws::Account.new.name_by_account(account_id)
              LOG.info "  Current AWS Account is #{account_name} (#{account_id})".light_yellow
              puts
              Dev::EndOfLife.new(product_versions: Dev::EndOfLife::Aws.new.default_products).status
              puts
            end
          end
        end
      end

      # Create the rake task for the hosted zone method
      def create_dns_logging_activate_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :aws do
            return if exclude.include?(:dns_logging)

            namespace :hosted_zone do
              namespace :dns_logging do
                desc 'Activates query logging for all hosted zones by default.' \
                     'This command should be run from the account the hosted zone(s) reside.' \
                     "\n\toptionally specify HOSTED_ZONE_GROUP='arn:aws:logs:REGION:ACCOUNT_ID:' to specify the ARN of the target log group." \
                     "\n\toptionally specify DOMAINS='foo.com,foobar.com' to specify the hosted zones to activate." \
                     "\n\t\tComma delimited list."
                task :activate do
                  route53 = Dev::Aws::Route53.new
                  route53.hosted_zones(ENV['DOMAINS'].to_s.strip.split(','))
                  # Use user defined log group. Otherwise, go get the default.
                  log_group = (ENV['HOSTED_ZONE_GROUP'] || Dev::Aws::Parameter.new.get_value('/Firespring/Internal/Route53/hosted-zone/log-group-arn'))
                  route53.activate_query_logging(log_group)
                end
              end
            end
          end
        end
      end

      # Create the rake task for the hosted zone method
      def create_dns_logging_deactivate_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :aws do
            return if exclude.include?(:dns_logging_de)

            namespace :hosted_zone do
              namespace :dns_logging do
                desc 'Deactivates query logging for all hosted zones by default. ' \
                     'This command should be run from the account the hosted zone(s) reside.' \
                     "\n\toptionally specify DOMAINS='foo.com,foobar.com' to specify the hosted zones to activate." \
                     "\n\t\tComma delimited list."
                task :deactivate do
                  route53 = Dev::Aws::Route53.new
                  route53.hosted_zones(ENV['DOMAINS'].to_s.strip.split(','))
                  route53.deactivate_query_logging
                end
              end
            end
          end
        end
      end
    end
  end
end
