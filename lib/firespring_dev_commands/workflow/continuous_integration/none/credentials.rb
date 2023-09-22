module Dev
  module Workflow
    module ContinuousIntegration
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
