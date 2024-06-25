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

          task eol: [:'eol:aws'] do
            # This is just a placeholder to execute the dependencies
          end

          namespace :eol do
            desc 'Compares the current date to the EOL date for supported aws resources'
            task aws: %w(init ensure_aws_credentials) do
              next if ENV.fetch('CHECK_AWS', nil).to_s.strip == 'false'

              aws_products = Dev::EndOfLife::Aws.new.default_products
              next if aws_products.empty?

              puts
              account_id = Dev::Aws::Profile.new.current
              account_name = Dev::Aws::Account.new.name_by_account(account_id)
              puts "AWS product versions (in account #{account_name} / #{account_id})".light_yellow
              Dev::EndOfLife.new(product_versions: aws_products).status
            end
          end
        end
      end
    end
  end
end
