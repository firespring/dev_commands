module Dev
  class TargetProcess
    # Class containing project information
    class TeamAssignment
      # The resource type for the api endpoint
      RESOURCE_TYPE = 'TeamAssignments'.freeze

      # The api path for team assignment requests
      PATH = "/#{RESOURCE_TYPE}".freeze

      attr_accessor :id, :type, :start_date, :end_date, :team, :story

      def initialize(data)
        @id = data['Id']
        @type = data['ResourceType']
        @start_date = parse_time(data['StartDate'])
        @end_date = parse_time(data['EndDate'])
        @team = Team.new(data['Team']) if data['Team']
        @story = UserStory.new(data['Assignable']) if data['Assignable']
      end

      # Parse the dot net time representation into something that ruby can use
      def parse_time(string)
        return nil unless string && !string.empty?

        Time.at(string.slice(6, 10).to_i)
      end

      # Calculate the cycle time as the amount of time the story was open
      def cycle_time
        return 1.0 unless start_date && end_date

        (end_date - start_date).to_f / (60 * 60 * 24)
      end
    end
  end
end
