module Dev
  class Jira
    # Contains Jira user information
    # Jira does not make user information available through their normal api (they have an admin api that you can use)
    # Therefore, we've provided a "lookup" method which attempts to find the jira user id in a hash of user information
    # that you can configure
    class User
      attr_accessor :name, :email, :id, :type

      def initialize(name:, email:, id:, type: Type::OTHER)
        @name = name
        @email = email
        @id = id
        @type = type
      end

      # Returns true if the Jira user is categorized as a developer
      def developer?
        type == Type::DEVELOPER
      end

      # Returns the Jira user object which maps to the give user id
      # If none is found, it returns a Jira user object with only the id set
      def self.lookup(id)
        user = Dev::Jira.config.user_lookup_list&.find { |it| it.id == id }
        user ||= new(name: '', email: '', id:)
        user
      end
    end
  end
end
