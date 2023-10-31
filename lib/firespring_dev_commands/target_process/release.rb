module Dev
  class TargetProcess
    # Class containing release information
    class Release
      # The resource type for the api endpoint
      RESOURCE_TYPE = 'Release'.freeze

      # The api path for release requests
      PATH = '/Releases'.freeze

      attr_accessor :id, :type, :name, :start_date, :end_date, :custom_fields

      def initialize(data)
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['Name']
        @start_date = parse_time(data['StartDate'])
        @end_date = parse_time(data['EndDate'])
        @custom_fields = data['CustomFields']
      end

      # Parse the dot net time representation into something that ruby can use
      def parse_time(string)
        return nil unless string && !string.empty?

        Time.at(string.slice(6, 10).to_i)
      end
    end
  end
end
