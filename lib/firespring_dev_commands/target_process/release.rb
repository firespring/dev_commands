module Dev
  class TargetProcess
    # Class containing release information
    class Release
      attr_accessor :id, :type, :name

      def initialize(data)
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['Name']
      end
    end
  end
end
