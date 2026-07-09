module Dev
  class Aws
    class Account
      # Class which contains information about the Aws account
      class Info
        attr_accessor :name, :id

        def initialize(name, id)
          raise 'AWS account id must be a string' unless id.is_a?(String)

          @name = name
          @id = id
        end
      end
    end
  end
end
