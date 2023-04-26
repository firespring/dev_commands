module Dev
  class Node
    # Class which contains commands and customizations for node security audit reports
    class Audit
      attr_accessor :data

      def initialize(data)
        @data = JSON.parse(Dev::Common.new.strip_non_json(data))
      end

      # Convert the node audit data to the standardized audit report object
      def to_report
        ids = Set.new

        Dev::Audit::Report.new(
          data['vulnerabilities'].map do |_, vulnerability|
            # If the via ia a hash and the id is not already recorded, add the item to our report
            vulnerability['via'].map do |it|
              next unless it.is_a?(Hash)

              id = it['url']&.split('/')&.last
              next if ids.include?(id)

              ids << id
              Dev::Audit::Report::Item.new(
                id: id,
                name: vulnerability['name'],
                title: it['title'],
                url: it['url'],
                severity: vulnerability['severity'],
                version: it['range']
              )
            end
          end.flatten.compact
        )
      end
    end
  end
end
