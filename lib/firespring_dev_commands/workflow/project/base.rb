module Dev
  module Workflow
    module Project
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
