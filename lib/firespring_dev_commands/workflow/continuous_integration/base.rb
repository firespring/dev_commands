module Dev
  module Workflow
    module Cicd
      class Base
        def name
            raise 'not implemented'
        end
      end

      class Credentials
        class Base
          def active?
            raise 'not implemented'
          end
        end
      end
    end
  end
end
