module Dev
  class TargetProcess
    class Query
      attr_accessor :where, :incl, :take

      def initialize
        @where = []
        @incl = []
        @take = 250
      end

      def <<(item)
        where << item
      end

      def where=(item)
        if item.is_a?(Array)
          where.concat(item)
        else
          where << item
        end
      end

      def include=(item)
        if item.is_a?(Array)
          incl.concat(item)
        else
          incl << item
        end
      end

      def generate
        {}.tap do |clause|
          clause[:where] = where.join(' and ') unless where.nil? || where.empty?
          clause[:include] = "[#{incl.join(',')}]" unless incl.nil? || incl.empty?
          clause[:take] = take if take.to_i.positive?
        end
      end

      def to_s
        generate
      end

      def filter_by_user_story_ids(user_story_ids)
        self << "(Id in ('#{user_story_ids.join("', '")}'))"
      end

      def filter_by_project(projects)
        self << "(Project.Name in ('#{projects.join("', '")}'))"
      end

      def filter_by_states(states)
        self << "(EntityState.Name in ('#{states.join("', '")}'))" unless states.nil? || states.empty?
      end

      def filter_by_final
        self << "(EntityState.IsFinal eq 'true')"
      end

      def filter_by_end_dates(start_date, end_date)
        self << "(EndDate gt '#{start_date}')" if start_date
        self << "(EndDate lt '#{end_date}')" if end_date
      end

      def filter_by_missing_tests
        self << '(LinkedTestPlan is nil)'
      end
    end
  end
end
