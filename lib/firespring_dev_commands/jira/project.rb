module Dev
  class Jira
    # Contains information on the Jira project
    class Project
      attr_accessor :name

      def initialize(data)
        @name = data.project.name
        @name <<= ' DevOps' if /devops/i.match?(data.issuetype.name)
      end
    end
  end
end
