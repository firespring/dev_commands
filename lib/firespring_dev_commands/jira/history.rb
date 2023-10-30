require 'date'

module Dev
  class Jira
    # Class contains history data for jira objects
    class History
      attr_accessor :date, :id, :author, :created, :items

      def initialize(data)
        @data = data
        @id = data['id']
        @author = data['author']
        @items = data['items']
        @created = Time.parse(data['created'])
      end
    end
  end
end
