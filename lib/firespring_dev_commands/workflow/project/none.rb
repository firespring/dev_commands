module Dev
  module Workflow
    module Project
      class None < Base
        def initialize
          @credentials = Credentials.new
          @start = Start.new
          @review = Review.new
          @delete = Delete.new
          @finish = Finish.new
        end
      end
    end
  end
end
