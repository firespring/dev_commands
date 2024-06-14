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

      private def zones(&)
        if @domains.empty?
          each_zone(&)
        else
          zones_by_domain_names(@domains, &)
        end
      end

      private def each_zone
        Dev::Aws.each_page(client, :list_hosted_zones) do |response|
          response.hosted_zones&.each do |hosted_zone|
            next if hosted_zone.config.private_zone

            yield hosted_zone
          end
        end
      end

      private def each_zones_by_domain_names(domains)
        domains.each do |domain_name|
          client.list_hosted_zones_by_name({dns_name: domain_name}) do |response|
            target = response.hosted_zones.find { |it| it.name.chomp('.') == domain_name }
            raise "The #{domain_name} hosted zone not found." unless target

            yield target
          end
        end
      end

      private def zones_by_domain_names(domains)
        [].tap do |ary|
          domains.each do |domain_name|
            response = client.list_hosted_zones_by_name({dns_name: domain_name})
            target = response.hosted_zones.find { |it| it.name.chomp('.') == domain_name }
            raise "The #{domain_name} hosted zone not found." unless target

            ary << target
          end
        end
      end

      private def ip_address(domain)
        begin
          ip_address = Addrinfo.ip(domain.to_s)
          ip_address.ip_address
        rescue SocketError
          "Unable to resolve domain: #{domain}"
        end
      end

      private def target_config_id(zone_id)
        client.list_query_logging_configs(
          hosted_zone_id: zone_id,
          max_results: '1'
        ).query_logging_configs.first&.id
      end

      # Get the hosted zone details for the zone id
      private def details(zone_id)
        response = client.get_hosted_zone(id: zone_id)
        [response.hosted_zone, response.delegation_set]
      end

      private def pretty_puts(output)
        # Find the maximum length of the keys
        max_key_length = output.keys.map(&:to_s).max_by(&:length).length

        output.each do |key, value|
          puts "#{key.to_s.ljust(max_key_length)}\t=>\t#{value}"
        end
      end

      # TODO: Print info about the zone
      def list_zone_details
        zones do |zone|
          puts
          zone_details, delegation_set = details(zone.id)

          puts "#{zone_details.name.light_white} (#{zone_details.id}):"
          puts "  Delegation Set: #{delegation_set.id}"
          puts "  Zone Nameservers: #{delegation_set.name_servers.join(', ')}"
          puts "  Actual Nameservers: #{Dev::Dns::Nameserver.new(zone_details.name)&.provider&.type}"
          puts "  Actual IP Resolution: #{ip_address(zone_details.name)}"

          target_config_id = target_config_id(zone.id)
          if target_config_id
            puts "  Config\t=>\t#{target_config_id}".colorize(:green)
          else
            puts '  No query logging config assigned.'.colorize(:red)
          end
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
          puts '%-50s => %s' % [zone.name, message]
        end
      end

      def activate_query_logging(log_group)
        output = {}

        zones.each do |zone|
          response = client.create_query_logging_config(
            hosted_zone_id: zone.id,
            cloud_watch_logs_log_group_arn: log_group
          )
          output[zone.id] = response.location
        rescue ::Aws::Route53::Errors::ServiceError => e
          raise "Error: #{e.message}" unless e.instance_of?(::Aws::Route53::Errors::QueryLoggingConfigAlreadyExists)

          output[zone.id] = e.message
        end
        pretty_puts(output)
      end

      def deactivate_query_logging
        output = {}
        zones.each do |zone|
          target_config_id = target_config_id(zone.id)
          if target_config_id
            client.delete_query_logging_config(
              id: target_config_id
            )
            output[zone.id] = 'Query logging config removed.'.colorize(:green)
          else
            output[zone.id] = 'No query logging config assigned.'.colorize(:red)
          end
        end
        pretty_puts(output)
      end
    end
  end
end
