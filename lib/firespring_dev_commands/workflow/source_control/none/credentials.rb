module Dev
  module Workflow
    module SourceControl
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
