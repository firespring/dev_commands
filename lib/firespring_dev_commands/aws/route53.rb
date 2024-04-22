require 'aws-sdk-route53'

module Dev
  class Aws
    # Class for performing Route53 functions
    class Route53
      attr_reader :client, :zones

      def initialize
        @client = ::Aws::Route53::Client.new
      end

      def hosted_zones(domains)
        @zones = []
        if domains.empty?
          @zones = [].tap do |ary|
            Dev::Aws.each_page(client, :list_hosted_zones, {max_items: 2}) do |response|
              response.hosted_zones.each do |hosted_zone|
                ary << hosted_zone.id unless hosted_zone.config.private_zone
              end
            end
          end
        else
          domains.each do |domain_name|
            zone = client.list_hosted_zones_by_name({dns_name: domain_name, max_items: 1})
            target_name = zone.hosted_zones.first.name.chomp!('.')
            raise "The #{domain_name} hosted zone not found." if target_name != domain_name

            @zones << zone.hosted_zones.first.id
          end
        end
        raise 'Hosted zone(s) not found.' if @zones.empty?
      end

      def get_target_config_id(zone_id)
        client.list_query_logging_configs(
          hosted_zone_id: zone_id,
          max_results: '1'
        ).query_logging_configs.first.id
      end

      def activate_query_logging(log_group)
        output = {}

        @zones.each do |zone|
          response = client.create_query_logging_config(
            hosted_zone_id: zone,
            cloud_watch_logs_log_group_arn: log_group
          )
          output[zone] = response.location
        rescue ::Aws::Route53::Errors::ServiceError => e
          raise "Error: #{e.message}" unless e.instance_of?(::Aws::Route53::Errors::QueryLoggingConfigAlreadyExists)

          output[zone] = e.message
        end
        pp output
      end

      def deactivate_query_logging
        output = {}
        @zones.each do |zone|
          target_config_id = get_target_config_id(zone)
          if target_config_id
            client.delete_query_logging_config(
              id: target_config_id
            )
            output[zone] = 'Query logging config removed.'
          else
            output[zone] = 'No query logging config assigned.'
          end
        end
        pp output
      end
    end
  end
end
