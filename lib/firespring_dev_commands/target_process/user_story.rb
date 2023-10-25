module Dev
  class TargetProcess
    class UserStory
      PATH = '/UserStories'.freeze

      attr_accessor :type, :id, :name, :description, :start_date, :end_date, :create_date, :modify_date, :tags, :effort, :time_spent, :last_state_change_date, :project,
                    :owner, :creator, :release, :team, :priority, :state, :original_data

      def initialize(data)
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['Name']
        @description = data['Description']
        @state = data['EntityState']['Name']
        @project = Project.new(data['Project']) if data['Project']
        @owner = User.new(data['Owner']) if data['Owner']
        @creator = User.new(data['Creator']) if data['Creator']
        @release = Release.new(data['Release']) if data['Release']
        @team = Team.new(data['Team']) if data['Team']
        @start_date = parse_time(data['StartDate'])
        @end_date = parse_time(data['EndDate'])
        @create_date = parse_time(data['CreateDate'])
        @modify_date = parse_time(data['ModifyDate'])
        @tags = data['Tags']
        @effort = data['Effort']
        @time_spent = data['TimeSpent']
        @last_state_change_date = parse_time(data['LastStateChangeDate'])
        @original_data = original_data
      end

      # Parse the dot net time representation into something that ruby can use
      def parse_time(string)
        return nil unless string && !string.empty?

        Time.at(string.slice(6, 10).to_i)
      end

      def cycle_time
        return 1.0 unless start_date && end_date

        (end_date - start_date).to_f
      end
    end
  end
end
