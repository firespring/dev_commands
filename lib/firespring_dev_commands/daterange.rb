require 'active_support'
require 'active_support/core_ext'

module Dev
  # Module containing methods for calculating start/stop dates for given ranges
  module DateRange
    # Class contains methods for calculating a date range with an hourly interval
    class Hourly
      attr_accessor :date

      def initialize(date = nil)
        @date = date || DateTime.now
      end

      # The hour interval previous to the current date
      def previous
        raise 'not implemented'
      end

      # The hour interval for the current date
      def current
        raise 'not implemented'
      end

      # The hour interval after the current date
      def next
        raise 'not implemented'
      end
    end

    # Class contains methods for calculating a date range with an daily interval
    class Daily
      attr_accessor :date

      def initialize(date = nil)
        @date = date || DateTime.now
      end

      # The daily interval previous to the current date
      def previous
        @date = date.beginning_of_day - 1
        current
      end

      # The daily interval for the current date
      def current
        start = date.beginning_of_day
        stop = date.end_of_day
        [start, stop]
      end

      # The daily interval after the current date
      def next
        @date = date.end_of_day + 1
        current
      end
    end

    # Class contains methods for calculating a date range with an weekly interval
    class Weekly
      attr_accessor :date

      def initialize(date = nil)
        @date = date || DateTime.now
      end

      # The weekly interval previous to the current date
      def previous
        @date = date.beginning_of_week - 1
        current
      end

      # The weekly interval for the current date
      def current
        start = date.beginning_of_week
        stop = date.end_of_week
        [start, stop]
      end

      # The weekly interval after the current date
      def next
        @date = date.end_of_week + 1
        current
      end
    end

    # Class contains methods for calculating a date range with an monthly interval
    class Monthly
      attr_accessor :date

      def initialize(date = nil)
        @date = date || DateTime.now
      end

      # The monthly interval previous to the current date
      def previous
        @date = date.beginning_of_month - 1
        current
      end

      # The monthly interval for the current date
      def current
        start = date.beginning_of_month
        stop = date.end_of_month
        [start, stop]
      end

      # The monthly interval after the current date
      def next
        @date = date.end_of_month + 1
        current
      end
    end

    # Class contains methods for calculating a date range with an quarterly interval
    class Quarterly
      attr_accessor :date

      def initialize(date = nil)
        @date = date || DateTime.now
      end

      # The quarterly interval previous to the current date
      def previous
        @date = date.beginning_of_quarter - 1
        current
      end

      # The quarterly interval for the current date
      def current
        start = date.beginning_of_quarter
        stop = date.end_of_quarter
        [start, stop]
      end

      # The quarterly interval after the current date
      def next
        @date = date.end_of_quarter + 1
        current
      end
    end

    # Class contains methods for calculating a date range with an yearly interval
    class Yearly
      attr_accessor :date

      def initialize(date = nil)
        @date = date || DateTime.now
      end

      # The yearly interval previous to the current date
      def previous
        @date = date.beginning_of_year - 1
        current
      end

      # The yearly interval for the current date
      def current
        start = date.beginning_of_year
        stop = date.end_of_year
        [start, stop]
      end

      # The yearly interval after the current date
      def next
        @date = date.end_of_year + 1
        current
      end
    end
  end
end
