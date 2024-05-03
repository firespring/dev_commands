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

      # Returns the node options for generating code coverage file
      def node_options
        []
      end

      # Returns the ruby options for generating code coverage file
      def ruby_options
        []
      end

      # Checks the code coverage against the defined threshold
      def check(*)
        # Nothing to do here
      end
    end
  end
end
