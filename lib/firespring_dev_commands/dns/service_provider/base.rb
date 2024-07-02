module Dev
  class Dns
    class ServiceProvider
      class BaseProvider
        def ips
          raise 'not implemented'
        end

        def type
          raise 'not implemented'
        end

        def has?(target)
          ips.include?(target)
        end
      end
    end
  end
end
