require_relative '../../base_interface'

module Dev
  module Template
    class Aws
      module Services
        # Class contains rake templates for managing your AWS settings and logging in
        class Route53 < Dev::Template::BaseInterface
          def create_list_zone_details_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            exclude = @exclude

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              return if exclude.include?(:list_details)

              namespace :aws do
                namespace :hosted_zone do
                  desc 'print details for all hosted zones'
                  task list_details: %w(ensure_aws_credentials) do
                    route53 = Dev::Aws::Route53.new(ENV['DOMAINS'].to_s.strip.split(','))
                    route53.list_zone_details
                  end
                end
              end
            end
          end

          # Create the rake task for the hosted zone method
          def create_dns_logging_activate_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            exclude = @exclude

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              return if exclude.include?(:dns_logging_activate)

              namespace :aws do
                namespace :hosted_zone do
                  namespace :dns_logging do
                    desc 'Activates query logging for all hosted zones by default.' \
                         'This command should be run from the account the hosted zone(s) reside.' \
                         "\n\t(Required) Specify LOG_GROUP_ARN='arn:aws:logs:REGION:ACCOUNT_ID:' to specify the ARN of the target log group." \
                         "\n\toptionally specify DOMAINS='foo.com,foobar.com' to specify the hosted zones to activate." \
                         "\n\t\tComma delimited list."
                    task activate: %w(ensure_aws_credentials) do
                      route53 = Dev::Aws::Route53.new(ENV['DOMAINS'].to_s.strip.split(','))
                      # Use user defined log group.
                      log_group = ENV.fetch('LOG_GROUP_ARN', nil)
                      raise 'The Hosted Zone Log Group ARN, LOG_GROUP_ARN, is required' unless log_group

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
              return if exclude.include?(:dns_logging_deactivate)

              namespace :aws do
                namespace :hosted_zone do
                  namespace :dns_logging do
                    desc 'Deactivates query logging for all hosted zones by default. ' \
                         'This command should be run from the account the hosted zone(s) reside.' \
                         "\n\toptionally specify DOMAINS='foo.com,foobar.com' to specify the hosted zones to activate." \
                         "\n\t\tComma delimited list."
                    task deactivate: %w(ensure_aws_credentials) do
                      route53 = Dev::Aws::Route53.new(ENV['DOMAINS'].to_s.strip.split(','))
                      route53.deactivate_query_logging
                    end
                  end
                end
              end
            end
          end

          # Create the rake task for the hosted zone method
          def create_list_query_config_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            exclude = @exclude

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              return if exclude.include?(:dns_logging_config)

              namespace :aws do
                namespace :hosted_zone do
                  namespace :dns_logging do
                    desc 'Lists the current config for domain(s). ' \
                         'This command should be run from the account the hosted zone(s) reside.' \
                         "\n\toptionally specify DOMAINS='foo.com,foobar.com' to specify the hosted zones to activate." \
                         "\n\t\tComma delimited list."
                    task list_query_configs: %w(ensure_aws_credentials) do
                      route53 = Dev::Aws::Route53.new(ENV['DOMAINS'].to_s.strip.split(','))
                      route53.list_query_configs
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
