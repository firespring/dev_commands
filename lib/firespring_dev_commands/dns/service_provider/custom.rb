require_relative 'base'

module Dev
  class Dns
    class ServiceProvider
      class CustomProvider < BaseProvider
        attr_reader :name, :ips

        def initialize(name, ips)
          @name = name
          @ips = ips
          super()
        end

        def type
          "#{name} IP".cyan.freeze
        end
      end
    end
  end
end
