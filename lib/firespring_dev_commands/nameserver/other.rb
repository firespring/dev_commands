require_relative 'base'

module Dev
  class Dns
    class Nameserver
      class Other < Base
        def type
          'Other'.light_white.freeze
        end
      end
    end
  end
end
