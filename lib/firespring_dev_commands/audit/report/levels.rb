module Dev
  class Audit
    class Report
      # Contains constants representing different audit report severity levels
      class Level
        # "info" severity level
        INFO = 'info'.freeze

        # "low" severity level
        LOW = 'low'.freeze

        # "moderate" severity level
        MODERATE = 'moderate'.freeze

        # "high" severity level
        HIGH = 'high'.freeze

        # "critical" severity level
        CRITICAL = 'critical'.freeze

        # "unknown" severity level
        UNKNOWN = 'unknown'.freeze
      end

      # All supported audit report levels in ascending order of severity
      LEVELS = [
        Level::INFO,
        Level::LOW,
        Level::MODERATE,
        Level::HIGH,
        Level::CRITICAL,
        Level::UNKNOWN
      ].freeze
    end
  end
end
