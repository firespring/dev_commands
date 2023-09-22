module Dev
  module Workflow
    module Project
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
