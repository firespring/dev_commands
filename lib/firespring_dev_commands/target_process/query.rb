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
        {}.tap { |clause|
          clause[:where] = where.join(' and ') unless where.nil? || where.empty?
          clause[:include] = "[#{incl.join(',')}]" unless incl.nil? || incl.empty?
          clause[:take] = take if take.to_i.positive?
        }
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
        self << "(LinkedTestPlan is nil)"
      end

=begin
    def format_story_info(stories)
      stories.map { |it|
        name = it['Name']
        cycle_time = ((Time.now - TargetProcess.parse_dot_net_time(it['StartDate'])) / 60 / 60 / 24).round(1)
        points = it['Effort'].to_i
        time_spent = it['TimeSpent'].to_i
        "#{TargetProcess::truncate(name)}  (#{cycle_time}d/#{points}pts/#{time_spent}hrs)"
      }
    end

    def self.bug_info(team_ids, start_date, end_date)
      finished_story_ids = TargetProcess::TeamAssignment.stories_finished_by_team(team_ids, start_date, end_date).map { |it| it['Assignable']['Id'] }

      query = Query.new
      filter_by_user_story_ids(query, finished_story_ids)
      query.include = 'Bugs'
      TargetProcess::get_helper('/UserStories', query)
    end

=end

    end
  end
end
