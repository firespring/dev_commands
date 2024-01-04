module Dev
  class TargetProcess
    # Class for writing target process query statements
    class Query
      attr_accessor :where, :incl, :take, :empty

      def initialize
        @where = []
        @incl = []
        @take = 250
        @empty = false
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

      # Check if any of the "in" statements were empty. If so then we don't want to actually run the query
      def empty?
        @empty == true
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
        if user_story_ids.nil? || user_story_ids.empty?
          @empty = true
          return
        end
        self << "(Id in ('#{user_story_ids.join("', '")}'))"
      end

      # Add a filter that looks for stories whose team id is contained in the list of ids given
      def filter_by_team_ids(team_ids)
        if team_ids.nil? || team_ids.empty?
          @empty = true
          return
        end
        self << "(Team.Id in ('#{team_ids.join("', '")}'))"
      end

      # Add a filter that looks for stories whose project id is contained in the list of ids given
      def filter_by_project(projects)
        if projects.nil? || projects.empty?
          @empty = true
          return
        end
        self << "(Project.Name in ('#{projects.join("', '")}'))"
      end

      # Add a filter that looks for stories whose state is contained in the list of states given
      def filter_by_states(states)
        if states.nil? || states.empty?
          @empty = true
          return
        end
        self << "(EntityState.Name in ('#{states.join("', '")}'))"
      end

      # Add a filter that looks for stories whose state is set to final
      def filter_by_final
        self << "(EntityState.IsFinal eq 'true')"
      end

      # Add a filter that looks for start dates between the given dates`
      def filter_start_date_between(start_date, end_date)
        self << "(StartDate gte '#{start_date}')" if start_date
        self << "(StartDate lt '#{end_date}')" if end_date
      end

      # Add a filter that looks for stories whose end date is between the given dates
      def filter_end_date_between(start_date, end_date)
        self << "(EndDate gte '#{start_date}')" if start_date
        self << "(EndDate lt '#{end_date}')" if end_date
      end

      # Add a filter that looks for entities whose date is between the given dates
      def filter_date_between(start_date, end_date)
        self << "(Date gte '#{start_date}')" if start_date
        self << "(Date lt '#{end_date}')" if end_date
      end

      # Add a filter that looks for stories which do not have a linked test plan
      def filter_by_missing_tests
        self << '(LinkedTestPlan is nil)'
      end

      # Add a filter that looks for items with a set start date and null end date
      def filter_by_started_not_finished
        self << '(StartDate is not nil)'
        self << '(EndDate is nil)'
      end

      # Add a filter that looks for assignable entity types that match the name
      def filter_by_entity_type(entity_type)
        self << "(Assignable.EntityType.Name eq '#{entity_type}')" unless entity_type.nil?
      end

      # Add a filter that looks for assignable id that match the given id
      def filter_by_entity_id(entity_id)
        self << "(Assignable.Id eq '#{entity_id}')" unless entity_id.nil?
      end

      # Add a filter that looks for assignable ids which are included in the given array
      def filter_by_entity_ids(entity_ids)
        if entity_ids.nil? || entity_ids.empty?
          @empty = true
          return
        end
        self << "(Assignable.Id in ('#{entity_ids.join("', '")}'))"
      end

      # Add a filter that looks for a custom deploy date between the given dates`
      def filter_by_deploy_date(start_date, end_date = nil)
        self << "('CustomFields.Deploy Date' gt '#{start_date}')" if start_date
        self << "('CustomFields.Deploy Date' lt '#{end_date}')" if end_date
      end
    end
  end
end
