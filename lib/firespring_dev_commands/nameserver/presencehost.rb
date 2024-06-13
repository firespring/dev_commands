require_relative 'base'

module Dev
  class Dns
    class Nameserver
      class Presencehost < Base
        def domains
          [
            'ns-1387.awsdns-45.org',
            'ns-2009.awsdns-59.co.uk',
            'ns-819.awsdns-38.net',
            'ns-388.awsdns-48.com',
          ].freeze
        end

        def type
          'Presencehost'.light_white.freeze
        end
      end
    end
  end
end
