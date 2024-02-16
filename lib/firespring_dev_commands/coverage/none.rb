module Dev
  # Module with a variety of coverage methods for different languages
  module Coverage
    # Class which provides methods to effectvely skip coverage
    class None < Base
      def initialize(*)
        super()
      end

      # Returns the php options for generating code coverage file
      def php_options
        []
      end

      # Checks the code coverage against the defined threshold
      def check(*)
        puts 'Coverage not configured'
      end
    end
  end
end
