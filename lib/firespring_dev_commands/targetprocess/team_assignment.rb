class TargetProcess
  class TeamAssignment
    def self.stories_in_progress_by_team(team_ids)
      query = Query.new
      filter_by_team_ids(query, team_ids)
      filter_by_in_progress(query)
      filter_by_entity_type(query, 'UserStory')

      TargetProcess::get_helper("/TeamAssignments", query)
    end

    def self.bug_ids_by_team(team_ids, start_date, end_date)
      query = Query.new
      filter_by_team_ids(query, team_ids)
      filter_by_start_date(query, start_date.to_date, end_date.to_date)
      filter_by_entity_type(query, 'Bug')

      results = TargetProcess::get_helper("/TeamAssignments", query)
      results.map { |it|
        it['Assignable']['Id']
      }
    end

    def self.stories_finished_by_team(team_ids, start_date, end_date)
      TargetProcess::TeamAssignment::entities_finished_by_team(team_ids, 'UserStory', start_date, end_date)
    end

    def self.story_ids_finished_by_team(team_ids, start_date, end_date)
      results = TargetProcess::TeamAssignment::stories_finished_by_team(team_ids, start_date, end_date)
      results.map { |it|
        it['Assignable']['Id']
      }
    end

    def self.entities_finished_by_team(team_ids, entity_type, start_date, end_date)
      query = Query.new
      filter_by_team_ids(query, team_ids)
      filter_by_finish_date(query, start_date.to_date, end_date.to_date)
      filter_by_entity_type(query, entity_type)

      TargetProcess::get_helper("/TeamAssignments", query)
    end

    def self.stories_filtered_by_team(team_ids, entity_ids)
      TargetProcess::TeamAssignment::entities_filtered_by_team(team_ids, entity_ids, 'UserStory')
    end

    def self.entities_filtered_by_team(team_ids, entity_ids, entity_type)
      query = Query.new
      filter_by_team_ids(query, team_ids)
      filter_by_entity_ids(query, entity_ids)
      filter_by_entity_type(query, entity_type)

      TargetProcess::get_helper("/TeamAssignments", query)
    end

    def self.filter_by_finish_date(query, start_date, end_date)
      query << "(EndDate gte '#{start_date}')" if start_date
      query << "(EndDate lt '#{end_date}')" if end_date
    end

    def self.filter_by_start_date(query, start_date, end_date)
      query << "(StartDate gt '#{start_date}')" if start_date
      query << "(StartDate lt '#{end_date}')" if end_date
    end

    def self.filter_by_in_progress(query)
      query << "(StartDate is not nil)"
      query << "(EndDate is nil)"
    end

    def self.filter_by_team_ids(query, team_ids)
      query << "(Team.Id in ('#{team_ids.join("', '")}'))" unless team_ids.nil? || team_ids.empty?
    end

    def self.filter_by_entity_type(query, entity_type)
      query << "(Assignable.EntityType.Name eq '#{entity_type}')" unless entity_type.nil?
    end

    def self.filter_by_entity_ids(query, entity_ids)
      query << "(Assignable.Id in ('#{entity_ids.join("', '")}'))" unless entity_ids.nil? || entity_ids.empty?
    end
  end
end
