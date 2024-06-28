module Dev
  class Dns
    class Resource
      attr_reader :domain, :ip_address

      def initialize(ip_or_domain)
        if ip?(ip_or_domain)
          @domain = nil
          @ip_address = ip_or_domain
        else
          @domain = ip_or_domain
          @ip_address = nil
        end
      end

      private def ip?(value)
        value.match?(Resolv::IPv4::Regex) || value.match?(Resolv::IPv6::Regex)
      end

      # If we don't have an IP address, that means the user passed in a domain.
      # Look it up now since the user wants the IP address
      def ip_address
        @ip_address ||= lookup(domain, type: Resolv::DNS::Resource::IN::A)
      end

      def recursive_nameserver_lookup(name = domain)
        type = Resolv::DNS::Resource::IN::NS
        records = lookup(name, type:)

        # Strip the subdomain and try again if we didn't find any nameservers (this can happen with wildcards)
        return recursive_nameserver_lookup(name.split('.', 2).last) if records.empty?

        records
      end

      # Lookup the given name using the record type provided.
      # 
      def lookup(name = domain, type: Resolv::DNS::Resource::IN::A)
        raise 'lookup type must be a Resolve::DNS::IN' unless type.ancestors.include?(Resolv::DNS::Resource)

        # If we've stripped subdomains to the point where we are at a tld
        return [] unless name.include?('.')

        # Look up NS records for the given host
        records = Resolv::DNS.new.getresources(name, type)

        records.map { |record| record.name.to_s }
      rescue
        []
      end
    end
  end
end
