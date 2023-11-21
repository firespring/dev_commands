module Dev
  class TargetProcess
    # Class containing project information
    class Project
      attr_accessor :date, :id, :type, :name

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['Name']
      end
    end
  end
end
