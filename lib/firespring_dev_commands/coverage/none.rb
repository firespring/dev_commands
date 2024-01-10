module Dev
  module Coverage
    class None < Base
      def initialize(*)
        super()
      end

      def php_options
        []
      end

      def check(*)
        puts 'Coverage not configured'
      end
    end
  end
end
