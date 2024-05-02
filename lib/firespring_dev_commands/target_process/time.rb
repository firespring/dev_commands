module Dev
  class TargetProcess
    # The class to query time information from Target Process
    class Time
      # The resource type for the api endpoint
      RESOURCE_TYPE = 'Time'.freeze

      # The api path for time requests
      PATH = '/Time'.freeze

      attr_accessor :data, :id, :type, :description, :hours, :date, :story, :user

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['ResourceType']
        @description = data['Description']
        @hours = data['Spent']
        @date = parse_time(data['Date'])
        @story = UserStory.new(data['Assignable']) if data['Assignable']
        @user = User.new(data['User']) if data['User']
      end

      # Parse the dot net time representation into something that ruby can use
      def parse_time(string)
        return nil unless string && !string.empty?

        ::Time.at(string.slice(6, 10).to_i)
      end
    end
  end
end
