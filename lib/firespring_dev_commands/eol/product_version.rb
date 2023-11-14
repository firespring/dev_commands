require 'date'

module Dev
  class EndOfLife
    # Class which tracks a specific product and provides methods for determining the end of life date
    class ProductVersion
      attr_accessor :name, :cycle, :eol, :description

      def initialize(name, cycle, description = nil)
        @name = name
        @cycle = cycle
        @eol_date = nil
        @eol = nil
        @description = description
      end

      # Print the status information for the product with additional coloring to show eol status
      def print_status
        puts to_s_colorize
      end

      # Returns whether this product version is currently EOL
      def eol
        populate_eol_info unless @eol
        @eol
      end

      # Returns the date at which this product is EOL
      def eol_date
        populate_eol_info unless @eol_date
        @eol_date
      end

      # Populates the eol and eol_date values
      # If eol is a boolean then the eol_date will be set to nil
      def populate_eol_info
        detail = product_detail(name, cycle)
        eol = detail['eol']
        if eol.boolean?
          @eol = eol
        else
          @eol_date = Date.parse(eol)
          @eol = @eol_date < Date.today
        end
      end

      # Returns the product details for the product and cycle based off the api response and any manually configured dates
      def product_detail(product, cycle)
        detail = {}

        uri = URI.parse("#{END_OF_LIFE_API_URL}/#{product}/#{cycle}.json")
        response = Net::HTTP.get_response(uri)
        detail = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

        # If EOL info is a boolean or missing from the current details, overwrite with the manual date (if present)
        manual_date = Dev::EndOfLife.config.manual_dates["#{product}_#{cycle.tr('.', '_')}".to_sym]
        detail['eol'] = manual_date if manual_date && (detail['eol'].boolean? || detail['eol'].nil?)
        detail['eol'] = '1979-01-01' if detail.empty?
        detail
      end

      # Returns a string representation of the product and its eol status
      def to_s
        message = "  #{name} (#{cycle}) is EOL on #{eol_date || 'n/a'}"
        message << " (#{(eol_date - Date.today).to_i} days)" if eol_date
        format '%-60s %s', message, description
      end

      # Returns the string representation of the product with additional coloring
      def to_s_colorize
        return to_s.light_red if eol

        if eol_date
          return to_s.light_green if eol_date > (Date.today + 240)
          return to_s.light_yellow if eol_date > (Date.today + 60)

          return to_s.light_magenta
        end

        to_s.light_white
      end
    end
  end
end
