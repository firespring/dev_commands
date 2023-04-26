require 'json'

module Dev
  class Ruby
    # Class which contains commands and customizations for security audit reports
    class Audit
      attr_accessor :data

      def initialize(data)
        @data = JSON.parse(Dev::Common.new.strip_non_json(data))
      end

      # Convert the php audit data to the standardized audit report object
      def to_report
        Dev::Audit::Report.new(
          data['results'].map do |it|
            Dev::Audit::Report::Item.new(
              id: it['advisory']['id'],
              name: it['gem']['name'],
              severity: it['advisory']['criticality'] || Dev::Audit::Report::Level::UNKNOWN,
              title: it['advisory']['title'],
              url: it['advisory']['url'],
              version: it['gem']['version']
            )
          end
        )
      end
    end
  end
end
