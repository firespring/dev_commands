module Dev
  class BloomGrowth
    # Class containing rock information
    class Rock
      attr_accessor :data, :id, :type, :name, :owner, :complete, :completion_id, :created, :due
      attr_reader :state

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['Type']
        @name = data['Name'].to_s.strip
        @owner = User.new(data['Owner']) if data['Owner']
        @complete = data['Complete']
        @completion_id = data['Completion']
        @created = Time.parse(data['CreateTime']) if data['CreateTime']
        @due = Time.parse(data['DueDate']) if data['DueDate']
        @archived = data['Archived']
      end

      # Convert the completion_id bloom growth gives us into a text version
      def state
        case completion_id
        when 0
          'Off Track'
        when 1
          'On Track'
        when 2
          'Complete'
        end
      end
    end
  end
end
