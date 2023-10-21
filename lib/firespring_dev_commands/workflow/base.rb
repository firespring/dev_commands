module Dev
  module Workflow
    class Base
      def initailze
        puts "IN BASE INIT"
        raise "not implemented"
      end

      def name
        self.class.name.demodulize
      end

      def start
        raise "not implemented"
      end

      def review
        raise "not implemented"
      end

      def finish
        raise "not implemented"
      end

      def delete
        raise "not implemented"
      end
    end
  end
end
