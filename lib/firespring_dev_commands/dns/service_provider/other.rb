require_relative 'base'

module Dev
  class Dns
    class ServiceProvider
      class Other < BaseProvider
        def type
          'Other'.red.freeze
        end
      end
    end
  end
end
