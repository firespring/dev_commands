module Dev
  module Workflow
    class Base
      def initailze
        raise "not implemented"
      end

      def name
        self.class.name.demodulize
      end

      def start_desc
        raise "not implemented"
      end

      def start
        raise "not implemented"
      end

      def review_desc
        raise "not implemented"
      end

      def review
        raise "not implemented"
      end

      def delete_desc
        raise "not implemented"
      end

      def delete
        raise "not implemented"
      end

      def finish_desc
        raise "not implemented"
      end

      def finish
        raise "not implemented"
      end
    end
  end
end
