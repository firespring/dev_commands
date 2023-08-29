require 'pry'

module Dev
  class Jira
    class Histories
      def self.populate(data)
        return nil unless data.attrs.key?('changelog')

        data.changelog['histories'].map { |it| Jira::History.new(it) }
      end
    end
  end
end
