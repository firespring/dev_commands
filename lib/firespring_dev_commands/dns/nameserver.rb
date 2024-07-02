module Dev
  class Dns
    class Nameserver
      attr_reader :domain, :nameservers, :domain_nameservers

      def initialize(domain)
        @domain = domain.to_s.strip
        @nameservers = Dev::Aws::Dns::Config.config.nameservers
      end

      def custom_nameservers
        nameservers.each do |nameserver|
          yield Custom.new(nameserver[:name], nameserver[:domains])
        end
      end

      def domain_nameservers
        @domain_nameservers ||= lookup(domain)
      end

      def lookup(name = domain)
        # If we've stripped subdomains to the point where we are at a tld
        return [] unless name.include?('.')

        # Look up NS records for the given host
        records = Resolv::DNS.new.getresources(name, Resolv::DNS::Resource::IN::NS)

        # Strip the subdomain and try again if we didn't find any nameservers (this can happen with wildcards)
        return lookup(name.split('.', 2).last) if records.empty?

        records.map { |record| record.name.to_s }
      rescue
        []
      end

      def provider
        return Unknown.new if domain_nameservers.empty?

        if nameservers
          custom_nameservers do |instance|
            return instance if instance.all?(domain_nameservers)
          end
        end

        Other.new
      end

      def status
        "    #{'NS'.light_white}  => #{provider.type}"
      end
    end
  end
end
