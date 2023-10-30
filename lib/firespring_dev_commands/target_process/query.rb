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

      # TODO: Do these need moved to their associated entities?
      # Add a filter that looks for stories whose id is contained in the list of ids given
      def filter_by_user_story_ids(user_story_ids)
        self << "(Id in ('#{user_story_ids.join("', '")}'))"
      end

      def filter_by_team_ids(team_ids)
        self << "(Team.Id in ('#{team_ids.join("', '")}'))" unless team_ids.nil? || team_ids.empty?
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

      def filter_start_date_between(start_date, end_date)
        self << "(StartDate gte '#{start_date}')" if start_date
        self << "(StartDate lt '#{end_date}')" if end_date
      end

      # Add a filter that looks for stories whose end date is between the given dates
      def filter_end_date_between(start_date, end_date)
        self << "(EndDate gte '#{start_date}')" if start_date
        self << "(EndDate lt '#{end_date}')" if end_date
      end

      # Add a filter that looks for stories which do not have a linked test plan
      def filter_by_missing_tests
        self << '(LinkedTestPlan is nil)'
      end

      def filter_by_started_not_finished
        self << '(StartDate is not nil)'
        self << '(EndDate is nil)'
      end

      def filter_by_entity_type(entity_type)
        self << "(Assignable.EntityType.Name eq '#{entity_type}')" unless entity_type.nil?
      end

      def filter_by_entity_ids(entity_ids)
        self << "(Assignable.Id in ('#{entity_ids.join("', '")}'))" unless entity_ids.nil? || entity_ids.empty?
      end
    end
  end
end
