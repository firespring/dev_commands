module Dev
  module Workflow
    module Review
      class None
        class Credentials < Credentials::Base
          def active?
            true
          end
        end
      end
    end
  end
end
