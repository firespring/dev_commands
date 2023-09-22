module Dev
  module Workflow
    module ContinuousIntegration
      class Base
        attr_accessor :credentials, :start, :review, :delete, :finish

        def initialize
          raise 'not implemented'
        end

        def name
          self.class.name.demodulize
        end
      end

      class Credentials
        class Base
          def active?
            raise 'not implemented'
          end
        end
      end

      class Start
        class Base
        end
      end

      class Review
        class Base
        end
      end

      class Delete
        class Base
        end
      end

      class Finish
        class Base
        end
      end
    end
  end
end
