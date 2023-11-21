module Dev
  class TargetProcess
    # Class containing team information
    class Team
      attr_accessor :data, :id, :type, :name

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['Name']
      end
    end
  end
end
