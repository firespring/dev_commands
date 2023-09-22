module Dev
  module Workflow
    module SourceControl
      class None < Base
        def initialize
          @credentials = None::Credentials.new
          @start = None::Start.new
          @review = None::Review.new
          @delete = None::Delete.new
          @finish = None::Finish.new
        end
      end
    end
  end
end
