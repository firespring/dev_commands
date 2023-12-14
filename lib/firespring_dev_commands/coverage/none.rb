module Dev
  module Coverage
    class None < Base
      def initialize(*_, **_)
      end

      def options
        []
      end

      def check
        puts "Line coverage not checked"
      end
    end
  end
end
