module Dev
  class Dns
    class Nameserver
      attr_reader :domain, :nameservers

      def initialize(domain)
        @domain = domain.to_s.strip
      end

      def nameservers
        @nameservers ||= lookup(domain)
      end

      def lookup(name = domain)
        # If we've stripped subdomains to the point where we are at a tld
        return [] unless name.include?('.')

        # Look up NS records for the given host
        records = Resolv::DNS.new.getresources(name, Resolv::DNS::Resource::IN::NS)

        # Strip the subdomain and try again if we didn't find any nameservers (this can happen with wildcards)
        return lookup(name.split('.', 2).last) if records.empty?

        records.map { |record| record.name.to_s }

      rescue => e
        []
      end

      def provider
        return Unknown.new if nameservers.empty?

        [Route53, FireDns, Presencehost, Legacy].each do |clazz|
          instance = clazz.send(:new)
          return instance if instance.all?(nameservers)
        end

        Other.new
      end

      def status
        "    #{'NS'.light_white}  => #{provider.type}"
      end
    end
  end
end
