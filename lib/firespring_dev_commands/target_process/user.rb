module Dev
  class TargetProcess
    class User
      attr_accessor :id, :type, :name, :login

      def initialize(data)
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['FullName']
        @login = data['Login']
      end
    end
  end
end
