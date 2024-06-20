module Dev
  class Dns
    class Nameserver
      class Base
        def domains
          raise 'not implemented'
        end

        def type
          raise 'not implemented'
        end

        def all?(records)
          records.all? { |record| domains.include?(record) }
        end
      end
    end
  end
end
