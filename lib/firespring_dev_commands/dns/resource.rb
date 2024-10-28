require 'whois'

module Dev
  class Dns
    class Resource
      attr_reader :domain

      def initialize(domain)
        @domain = domain
      end

      # Returns whether or not the given value is a valid IPv4 or IPv6 address
      def self.ip?(value)
        ipv4?(value) || ipv6?(value)
      end

      # Returns whether or not the given value is a valid IPv4 address
      def self.ipv4?(value)
        value.match?(Resolv::IPv4::Regex)
      end

      # Returns whether or not the given value is a valid IPv6 address
      def self.ipv6?(value)
        value.match?(Resolv::IPv6::Regex)
      end

      # Determines the registrar(s) of the given name. Not perfect and can be rate limited.
      def registrar_lookup(name = domain)
        Whois.whois(name.chomp('.')).parts.map(&:host)
      rescue Whois::Error
        sleep(0.75)
        retry
      end

      # Recursively determine the correct nameservers for the given domain.
      # If nameservers are not found, strip subdomains off until we've reached the TLD
      def recursive_nameserver_lookup(name = domain)
        records = lookup(name, type: Resolv::DNS::Resource::IN::NS)

        # Strip the subdomain and try again if we didn't find any nameservers (this can happen with wildcards)
        return recursive_nameserver_lookup(name.split('.', 2).last) if records.empty?

        # Look up the IPs for the nameservers
        records
      end

      # Recursively attempt to find an A record for the given domain.
      # If one isn't found, also check for CNAMEs continually until we have either found an IP or run out of things to check
      def recursive_a_lookup(name = domain)
        # Try looking up an A record first. If we find one, we are done.
        records = lookup(name, type: Resolv::DNS::Resource::IN::A)
        return records unless records.empty?

        # Try looking up a CNAME record
        records = lookup(name, type: Resolv::DNS::Resource::IN::CNAME)

        # If we didn't find an A record _or_ a CNAME, just return empty
        return records if records.empty?

        # If we found more than one CNAME that is a DNS error
        raise "Found more than one CNAME entry for #{name}. This is not allowed by DNS" if records.length > 1

        recursive_a_lookup(records.first)
      end

      # Lookup the given name using the record type provided.
      def lookup(name = domain, type: Resolv::DNS::Resource::IN::A)
        # Validate the type
        raise 'lookup type must be a Resolv::DNS::Resource' unless type.ancestors.include?(Resolv::DNS::Resource)

        # If we were given a tld, return empty
        return [] unless name.include?('.')

        # Look up NS records for the given host
        records = Resolv::DNS.new.getresources(name, type)

        # Return the record names
        records.map do |record|
          if record.respond_to?(:address)
            record.address.to_s
          elsif record.respond_to?(:name)
            record.name.to_s
          else
            ''
          end
        end
      rescue
        sleep(1)
        retry
      end
    end
  end
end
