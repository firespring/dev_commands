module Dev
  module Coverage
    class None < Base
      def initialize(*)
        super()
      end

      def php_options
        []
      end

      def node_options
        []
      end

      def ruby_options
        []
      end

      def check(*)
        # Nothing to do here
      end
    end
  end
end
