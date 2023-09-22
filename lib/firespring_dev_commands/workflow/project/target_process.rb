module Dev
  module Workflow
    module Project
      class TargetProcess < Base
        def initialize
          @credentials = TargetProcess::Credentials.new
          @start = TargetProcess::Start.new
          @review = TargetProcess::Review.new
          @delete = TargetProcess::Delete.new
          @finish = TargetProcess::Finish.new
        end
      end
    end
  end
end
