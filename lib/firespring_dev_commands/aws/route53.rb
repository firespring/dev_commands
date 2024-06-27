require 'aws-sdk-route53'

module Dev
  class Aws
    # Class for performing Route53 functions
    class Route53
      attr_reader :client

      def initialize(domains = nil)
        @client = ::Aws::Route53::Client.new
        @domains = Array(domains || [])
      end

      def zones(&)
        if @domains.empty?
          each_zone(&)
        else
          each_zone_by_domains(&)
        end
      end

      private def each_zone
        Dev::Aws.each_page(client, :list_hosted_zones) do |response|
          response.hosted_zones&.each do |hosted_zone|
            next if hosted_zone.config.private_zone

            yield hosted_zone
          end
        rescue ::Aws::Route53::Errors::Throttling
          sleep(1)
          retry
        end
      end

      private def each_zone_by_domains(&)
        @domains.each do |domain|
          response = client.list_hosted_zones_by_name({dns_name: domain})

          # The 'list_hosted_zones_by_name' returns fuzzy matches (so "foo.com" would return both "bar.foo.com" and "foo.com"
          targets = response.hosted_zones.select { |it| it.name.chomp('.') == domain }
          raise "The #{domain} hosted zone not found." if targets.empty?

          targets.each(&)
        rescue ::Aws::Route53::Errors::Throttling
          sleep(1)
          retry
        end
      end

      private def ip_address(domain)
        Addrinfo.ip(domain.to_s.strip)&.ip_address
      rescue SocketError
        "Unable to resolve domain: #{domain}"
      end

      private def target_config_id(zone_id)
        client.list_query_logging_configs(
          hosted_zone_id: zone_id,
          max_results: '1'
        ).query_logging_configs&.first&.id
      end

      # Get the hosted zone details for the zone id
      private def details(zone_id)
        response = client.get_hosted_zone(id: zone_id)
        [response.hosted_zone, response.delegation_set]
      end

      def list_zone_details
        zones do |zone|
          puts
          zone_details, delegation_set = details(zone.id)
          target_config_id = target_config_id(zone.id)

          puts "#{zone_details.name.light_white} (#{zone_details.id}):"
          puts "  Delegation Set: #{delegation_set.id}"
          puts "  Zone Nameservers: #{delegation_set.name_servers.join(', ')}"
          puts "  Actual Nameservers: #{Dev::Dns::Nameserver.new(zone_details.name)&.provider&.type}"
          puts "  Actual IP Resolution: #{ip_address(zone_details.name)}"
          puts "  Website Provider: #{Dev::Dns::ServiceProvider.new(ip_address(zone_details.name))&.provider&.type}"
          if target_config_id
            puts "  Config\t=>\t#{target_config_id}".colorize(:green)
          else
            puts '  No query logging config assigned.'.colorize(:red)
          end
        rescue ::Aws::Route53::Errors::Throttling
          sleep(1)
          retry
        end
        puts
      end

      def list_query_configs
        zones do |zone|
          target_config_id = target_config_id(zone.id)
          message = if target_config_id
                      "Config\t=>\t#{target_config_id}".colorize(:green)
                    else
                      'No query logging config assigned.'.colorize(:red)
                    end
          puts format('%-50s => %s', zone.name, message)
        rescue ::Aws::Route53::Errors::Throttling
          sleep(1)
          retry
        end
      end

      def activate_query_logging(log_group)
        zones do |zone|
          response = client.create_query_logging_config(
            hosted_zone_id: zone.id,
            cloud_watch_logs_log_group_arn: log_group
          )
          puts format('%-50s => %s', zone.id, response.location)
        rescue ::Aws::Route53::Errors::Throttling
          sleep(1)
          retry
        rescue ::Aws::Route53::Errors::ServiceError => e
          raise "Error: #{e.message}" unless e.instance_of?(::Aws::Route53::Errors::QueryLoggingConfigAlreadyExists)

          puts format('%-50s => %s', zone.id, e.message)
        end
      end

      def deactivate_query_logging
        zones do |zone|
          target_config_id = target_config_id(zone.id)
          if target_config_id
            client.delete_query_logging_config(
              id: target_config_id
            )
            puts format('%-50s => %s', zone.id, 'Query logging config removed.'.colorize(:green))
          else
            puts format('%-50s => %s', zone.id, 'No query logging config assigned.'.colorize(:red))
          end
        rescue ::Aws::Route53::Errors::Throttling
          sleep(1)
          retry
        end
      end
    end
  end
end
