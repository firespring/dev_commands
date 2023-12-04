module Dev
  # Class containing security audit information
  class Audit
    # The class containing standardized information about an audit report
    class Report
      attr_accessor :items, :min_severity, :error_on_unknown, :ignorelist, :filtered_items

      def initialize(
        items,
        min_severity: ENV.fetch('MIN_SEVERITY', nil),
        error_on_unknown: ENV.fetch('ERROR_ON_UNKNOWN', nil),
        ignorelist: ENV['IGNORELIST'].to_s.split(/\s*,\s*/)
      )
        # Items should be an array of Item objects
        @items = Array(items)
        raise 'items must all be report items' unless @items.all?(Dev::Audit::Report::Item)

        @min_severity = min_severity || Level::HIGH
        @ignorelist = Array(ignorelist).compact
      end

      # Get all severities greater than or equal to the minimum severity
      def desired_severities
        max_severity = if error_on_unknown.to_s.strip == 'true'
                         -1
                       else
                         -2
                       end
        LEVELS.slice(LEVELS.find_index(min_severity)..max_severity)
      end

      # Run the filters against the report items and filter out any which should be excluded
      def filtered_items
        @filtered_items ||= items.select { |it| desired_severities.include?(it.severity) }.select { |it| ignorelist.none?(it.id) }
      end

      # Output the text of the filtered report items
      # Exit with a non-zero status if any vulnerabilities were found
      def check
        puts(self)
        return if filtered_items.empty?

        at_exit { exit(1) }
      end

      # Returns a string representation of this audit report
      def to_s
        return 'No security vulnerabilities found'.green if filtered_items.empty?

        [].tap do |ary|
          ary << "Found #{filtered_items.length} security vulnerabilities:".white.on_red
          filtered_items.each { |item| ary << item.to_s }
        end.join("\n")
      end
    end
  end
end
