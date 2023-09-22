module Dev
  module Workflow
    module Project
      class Jira < Base
        def initialize
          @credentials = Jira::Credentials.new
          @start = Jira::Start.new
          @review = Jira::Review.new
          @delete = Jira::Delete.new
          @finish = Jira::Finish.new
        end
      end
    end
  end
end
