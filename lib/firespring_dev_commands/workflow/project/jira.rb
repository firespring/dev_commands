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

          @client = Dev::Jira.new(username: config.username, token: config.token, url: config.url)

          Dev::Jira.configure do |c|
            c.points_field_name = :customfield_10002
            c.expand = ['changelog']
          end

        end
      end
    end
  end
end
