module Dev
  class TargetProcess
    # Class containing user information
    class User
      # The resource type for the api endpoint
      RESOURCE_TYPE = 'User'.freeze

      # The api path for user requests
      PATH = '/User'.freeze

      attr_accessor :data, :id, :type, :name, :login, :email

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['FullName']
        @login = data['Login']
        @email = data['Email']
      end

      # Get the user with the given id and return that object
      def self.get(id)
        new(TargetProcess.new.get("#{User::PATH}/#{id}", Query.new))
      end
    end
  end
end
