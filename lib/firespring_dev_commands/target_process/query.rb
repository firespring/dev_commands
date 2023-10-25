module Dev
  class TargetProcess
    # Class for writing target process query statements
    class Query
      attr_accessor :where, :incl, :take

      def initialize
        @where = []
        @incl = []
        @take = 250
      end

      # Add a new query clause
      def <<(item)
        where << item
      end

      # Add the item to the where clause
      def where=(item)
        if item.is_a?(Array)
          where.concat(item)
        else
          where << item
        end
      end

      # Add the item to the include clause
      def include=(item)
        if item.is_a?(Array)
          incl.concat(item)
        else
          incl << item
        end
      end

      # Generate the string representation for this query
      def generate
        {}.tap do |clause|
          clause[:where] = where.join(' and ') unless where.nil? || where.empty?
          clause[:include] = "[#{incl.join(',')}]" unless incl.nil? || incl.empty?
          clause[:take] = take if take.to_i.positive?
        end
      end

      # Generate the string representation for this query
      def to_s
        generate
      end

      # Add a filter that looks for stories whose id is contained in the list of ids given
      def filter_by_user_story_ids(user_story_ids)
        self << "(Id in ('#{user_story_ids.join("', '")}'))"
      end

      # Add a filter that looks for stories whose project id is contained in the list of ids given
      def filter_by_project(projects)
        self << "(Project.Name in ('#{projects.join("', '")}'))"
      end

      # Add a filter that looks for stories whose state is contained in the list of states given
      def filter_by_states(states)
        self << "(EntityState.Name in ('#{states.join("', '")}'))" unless states.nil? || states.empty?
      end

      # Add a filter that looks for stories whose state is set to final
      def filter_by_final
        self << "(EntityState.IsFinal eq 'true')"
      end

      # Add a filter that looks for stories whose end date is between the given dates
      def filter_by_end_dates(start_date, end_date)
        self << "(EndDate gt '#{start_date}')" if start_date
        self << "(EndDate lt '#{end_date}')" if end_date
      end

      # Add a filter that looks for stories which do not have a linked test plan
      def filter_by_missing_tests
        self << '(LinkedTestPlan is nil)'
      end
    end
  end
end
