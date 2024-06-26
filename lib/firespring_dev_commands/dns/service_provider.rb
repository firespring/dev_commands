module Dev
  class Dns
    class ServiceProvider
      attr_reader :ip_address, :providers

      def initialize(ip_address)
        @ip_address = ip_address
        @providers = Dev::Aws::Dns::Config.config.providers
      end

      def service_providers
        providers.each do |service|
          yield CustomProvider.new(service[:name], service[:ips])
        end
      end

      def valid_ipv4?
        # Regular expression to match IPv4 addresses
        ipv4_regex = /\A((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/

        # Check if the input matches the regular expression
        !!(ip_address =~ ipv4_regex)
      end

      def provider
        return Unknown.new if ip_address.empty? || !valid_ipv4?

        if providers
          service_providers do |instance|
            return instance if instance.has?(ip_address)
          end
        end

        Other.new
      end

      def status
        "    #{'Host'.yellow}  => #{provider.type}"
      end
    end
  end
end
