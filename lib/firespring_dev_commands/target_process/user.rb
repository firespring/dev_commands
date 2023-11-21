module Dev
  class TargetProcess
    # Class containing user information
    class User
      attr_accessor :data, :id, :type, :name, :login

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['FullName']
        @login = data['Login']
      end
    end
  end
end
