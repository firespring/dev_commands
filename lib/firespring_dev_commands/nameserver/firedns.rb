require_relative 'base'

module Dev
  class Dns
    class Nameserver
      class FireDns < Base
        def domains
          ['ns1.firespring.com', 'ns2.firespring.com'].freeze
        end

        def type
          'Firespring using FireDNS'.light_white.freeze
        end
      end
    end
  end
end
