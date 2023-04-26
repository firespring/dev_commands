module Dev
  class Aws
    class Account
      # Class which contains information about the Aws account
      class Info
        attr_accessor :name, :id

        def initialize(name, id)
          @name = name
          @id = id
        end
      end
    end
  end
end
