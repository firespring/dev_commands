require_relative 'base'

module Dev
  class Dns
    class Nameserver
      class Route53 < Base
        def domains
          %w(ns1.firespringdns.com ns2.firespringdns.com ns3.firespringdns.com ns4.firespringdns.com).freeze
        end

        def type
          'Firespring using Route53'.light_white.freeze
        end
      end
    end
  end
end
