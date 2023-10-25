module Dev
  class Jira
    # Class which provides a helper method for converting the changelog data to history objects
    class Histories
      # If changelog is present in the given data, return an array of history objects for each changelog entry
      def self.populate(data)
        return nil unless data.attrs.key?('changelog')

        data.changelog['histories'].map { |it| Jira::History.new(it) }
      end
    end
  end
end
