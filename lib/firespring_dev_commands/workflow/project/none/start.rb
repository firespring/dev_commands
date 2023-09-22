module Dev
  module Workflow
    module Project
      class None
        class Start < Start::Base
          # This method performs project level pre-requisites for the given project type
          # This may include checks on the number of stories in progress or checks on correct story status
          def prerequisites
          end
        end
      end
    end
  end
end
