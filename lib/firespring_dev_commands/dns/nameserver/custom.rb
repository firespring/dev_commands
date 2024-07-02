module Dev
  class Dns
    class Nameserver
      class Custom < Base
        attr_reader :name, :domains

        def initialize(name, domains)
          @name = name
          @domains = domains
          super()
        end

        def type
          "#{name} nameserver".light_white.freeze
        end
      end
    end
  end
end
