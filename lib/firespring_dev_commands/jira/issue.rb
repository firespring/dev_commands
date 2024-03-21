module Dev
  class Jira
    # Contains information and methods representing a Jira issue
    class Issue
      # Issue subtypes which do not map to a story type
      NON_STORY_TYPES = ['epic', 'review', 'sub-task', 'code review sub-task', 'pre-deploy sub-task', 'deploy sub-task', 'devops sub-task'].freeze

      attr_accessor :data, :project, :parent, :id, :title, :points, :assignee, :resolved_date, :histories, :last_in_progress_history, :first_in_review_history, :last_closed_history

      def initialize(data)
        @data = data
        @project = Jira::Project.new(data)
        @parent = Jira::Parent.new(data) if data.respond_to?(:parent)
        @id = data.key
        @title = data.summary
        @points = calculate_points(data)
        @assignee = Jira::User.lookup(data.assignee&.accountId)
        @resolved_date = data.resolutiondate
        @histories = Jira::Histories.populate(data)
        @last_in_progress_history = nil
        @first_in_review_history = nil
        @last_closed_history = nil
      end

      # Returns the cycle time of the issue (time between in progress and closed states)
      def cycle_time
        # Calculate the difference and convert to days
        ((last_closed_history.created - last_in_progress_history.created) / 60 / 60 / 24).round(2)
      end

      # Returns the time the issue was in progress (time between in progress and in review states)
      def in_progress_cycle_time
        # Calculate the difference and convert to days
        ((first_in_review_history.created - last_in_progress_history.created) / 60 / 60 / 24).round(2)
      end

      # Returns the time the issue was in review (time between in review and closed states)
      def in_review_cycle_time
        # Calculate the difference and convert to days
        ((last_closed_history.created - first_in_review_history.created) / 60 / 60 / 24).round(2)
      end

      # Loop through the issue history and find the most recent state change from Open to In Progress
      private def last_in_progress_history
        raise 'you must expand the changelog field to calculate cycle time' if histories.nil?

        # Find the first instance in the histoy where the status moved to "In Progress"
        @last_in_progress_history ||= histories.select do |history|
          history.items.find do |item|
            item['fieldId'] == 'status' && item['fromString'] == 'Open' && item['toString'] == 'In Progress'
          end
        end.max_by(&:created)
        raise 'unable to find "In Progress" history entry needed to calculate cycle time' unless @last_in_progress_history

        @last_in_progress_history
      end

      # Loop through the issue history and find the oldest state change to In Review
      private def first_in_review_history
        raise 'you must expand the changelog field to calculate cycle time' if histories.nil?

        # Find the first instance in the histoy where the status moved to "In Review"
        @first_in_review_history ||= histories.select do |history|
          history.items.find do |item|
            item['fieldId'] == 'status' && item['toString'] == 'In Review'
          end
        end.min_by(&:created)
        raise 'unable to find "In Review" history entry needed to calculate cycle time' unless @first_in_review_history

        @first_in_review_history
      end

      # Loop through the issue history and find the most recent state change to closed
      private def last_closed_history
        raise 'you must expand the changelog field to calculate cycle time' if histories.nil?

        # Find the last instance in the histoy where the status moved to "Closed"
        @last_closed_history ||= histories.select do |history|
          history.items.find do |item|
            item['fieldId'] == 'status' && item['toString'] == 'Closed'
          end
        end.max_by(&:created)
        raise 'unable to find "Closed" history entry needed to calculate cycle time' unless @last_closed_history

        @last_closed_history
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
