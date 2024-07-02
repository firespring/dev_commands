require_relative 'base'

module Dev
  class Dns
    class ServiceProvider
      class Unknown < BaseProvider
        def type
          'Not Found'.light_white
        end
      end
    end
  end
end
