module Dev
  module Coverage
    # Class which defines the methods which must be implemented to function as a coverage class
    class Base
      # Raises not implemented
      def php_options
        raise 'not implemented'
      end

      # Raises not implemented
      def check(*)
        raise 'not implemented'
      end
    end
  end
end
