require_relative 'base'

module Dev
  class Dns
    class Nameserver
      class Legacy < Base
        def domains
          %w(ns1.digitalims.net ns2.digitalims.net).freeze
        end

        def type
          'Firespring Legacy'.light_white.freeze
        end
      end
    end
  end
end
