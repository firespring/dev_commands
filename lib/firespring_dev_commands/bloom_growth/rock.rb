module Dev
  class BloomGrowth
    # Class containing rock information
    class Rock
      attr_accessor :data, :id, :type, :name, :owner, :complete, :state, :created, :due

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['Type']
        @name = data['Name'].to_s.strip
        @owner = User.new(data['Owner']) if data['Owner']
        @complete = data['Complete']
        @state = completion_to_state(data['Completion'])
        @created = Time.parse(data['CreateTime']) if data['CreateTime']
        @due = Time.parse(data['DueDate']) if data['DueDate']
        @archived = data['Archived']
      end

      def completion_to_state(completion_id)
        case completion_id
        when 0
          'Off Track'
        when 1
          'On Track'
        when 2
          'Complete'
        end
      end

      def colorized_state
        return unless state
        return state.light_red if state.downcase.include?('off track')
        return state.light_green if state.downcase.include?('complete')

        state.light_white
      end
    end
  end
end
