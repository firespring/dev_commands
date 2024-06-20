require_relative 'base'

module Dev
  class Dns
    class Nameserver
      class Unknown < Base
        def type
          'Not Found'.light_white
        end
      end
    end
  end
end
