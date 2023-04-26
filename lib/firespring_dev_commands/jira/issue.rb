module Dev
  class Jira
    # Contains information and methods representing a Jira issue
    class Issue
      # Issue subtypes which do not map to a story type
      NON_STORY_TYPES = ['review', 'sub-task', 'code review sub-task', 'pre-deploy sub-task', 'deploy sub-task', 'devops sub-task'].freeze

      attr_accessor :data, :project, :id, :title, :points, :assignee, :resolved_date

      def initialize(data)
        @data = data
        @project = Jira::Project.new(data)
        @id = data.key
        @title = data.summary
        @points = calculate_points(data)
        @assignee = Jira::User.lookup(data.assignee&.accountId)
        @resolved_date = data.resolutiondate
      end

      # Returns the value of the jira points field or 0 if the field is not found
      def calculate_points(data)
        return data.send(Dev::Jira.config.points_field_name).to_i if Dev::Jira.config.points_field_name && data.respond_to?(Dev::Jira.config.points_field_name)

        0
      end

      # Converts the jira issue object to a string representation
      def to_s
        "[#{id}] #{title} (#{points} pts) (resolved #{resolved_date}"
      end
    end
  end
end
