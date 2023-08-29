module Dev
  class Jira
    # Contains information and methods representing a Jira issue
    class Issue
      # Issue subtypes which do not map to a story type
      NON_STORY_TYPES = ['review', 'sub-task', 'code review sub-task', 'pre-deploy sub-task', 'deploy sub-task', 'devops sub-task'].freeze

      attr_accessor :data, :project, :id, :title, :points, :assignee, :resolved_date, :histories

      def initialize(data)
        @data = data
        @project = Jira::Project.new(data)
        @id = data.key
        @title = data.summary
        @points = calculate_points(data)
        @assignee = Jira::User.lookup(data.assignee&.accountId)
        @resolved_date = data.resolutiondate
        @histories = Jira::Histories.populate(data)
      end

      def cycle_time
        raise 'you must expand the changelog field to calculate cycle time' if histories.nil?

        in_progress_history = histories.reverse.find { |history| history.items.find { |item| item['fieldId'] == 'status' && item['toString'] == 'In Progress' } }
        closed_history = histories.find { |history| history.items.find { |item| item['fieldId'] == 'status' && item['toString'] == 'Closed' } }

        # Calculate the difference and convert to days
        ((closed_history.created - in_progress_history.created) / 60 / 60 / 24).round(2)
      end

      def in_progress_cycle_time
        raise 'you must expand the changelog field to calculate cycle time' if histories.nil?

        in_progress_history = histories.reverse.find { |history| history.items.find { |item| item['fieldId'] == 'status' && item['toString'] == 'In Progress' } }
        in_review_history = histories.reverse.find { |history| history.items.find { |item| item['fieldId'] == 'status' && item['toString'] == 'In Review' } }

        # Calculate the difference and convert to days
        ((in_review_history.created - in_progress_history.created) / 60 / 60 / 24).round(2)
      end

      def in_review_cycle_time
        raise 'you must expand the changelog field to calculate cycle time' if histories.nil?

        in_review_history = histories.reverse.find { |history| history.items.find { |item| item['fieldId'] == 'status' && item['toString'] == 'In Review' } }
        closed_history = histories.find { |history| history.items.find { |item| item['fieldId'] == 'status' && item['toString'] == 'Closed' } }

        # Calculate the difference and convert to days
        ((closed_history.created - in_review_history.created) / 60 / 60 / 24).round(2)
      end

      # Returns the value of the jira points field or 0 if the field is not found
      private def calculate_points(data)
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
