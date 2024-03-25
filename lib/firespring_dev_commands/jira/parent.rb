module Dev
  class Jira
    # Contains information on the Jira parent issue
    class Parent
      attr_accessor :data, :id, :title

      def initialize(data)
        @data = data.parent
        @id = data.parent['key']
        @title = data.parent['fields']['summary']
      end

      # Converts the jira parent object to a string representation
      def to_s
        "[#{id}] #{title}"
      end
    end
  end
end
