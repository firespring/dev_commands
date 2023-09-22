module Dev
  module Workflow
    module ContinuousIntegration
      class Base
        def name
          raise 'not implemented'
        end

        class Start
        end

        class Review
        end

        class Delete
        end

        class Finish
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
end
