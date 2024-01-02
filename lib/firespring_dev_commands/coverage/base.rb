module Dev
  module Coverage
    class Base
      def php_options
        raise 'not implemented'
      end

      def check(*)
        raise 'not implemented'
      end
    end
  end
end
