require 'aws-sdk-route53'

module Dev
  class Aws
    # Class for performing Route53 functions
    class Route53
      attr_reader :client, :zones

      def initialize
        @client = ::Aws::Route53::Client.new
        @zones = []
      end

      def get_hosted_zones(domains)
        if domains.empty?
          response = client.list_hosted_zones
          response.hosted_zones.each do |hosted_zone|
            @zones << hosted_zone.id
          end
        else
          domains.each do |domain_name|
            zone = client.list_hosted_zones_by_name({dns_name: domain_name, max_items: 1})
            target_name = zone.hosted_zones[0].name.chomp!('.') if zone.hosted_zones[0].name.end_with?('.')
            @zones << zone.hosted_zones[0].id unless target_name != domain_name
          end
        end
        raise 'Hosted zone(s) not found.' if @zones.empty?
      end

      def get_target_config_id(zone_id)
        config = client.list_query_logging_configs(
          hosted_zone_id: zone_id,
          max_results: '1'
        )
        config.query_logging_configs[0].id unless config.query_logging_configs.empty? || config.query_logging_configs[0].hosted_zone_id == zone_id
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
