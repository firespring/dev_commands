class TargetProcess
  class Bug
    def self.total_opened_by(start_date, end_date, owner_team_ids, owner_role_ids = nil)
      user_ids = TargetProcess::Team.member_user_ids(owner_team_ids, owner_role_ids)

      return 0 if user_ids.empty?

      query = Query.new
      filter_by_create_dates(query, start_date, end_date)
      filter_by_owner(query, user_ids)
      filter_out_state(query, 'Not A Bug')

      results = TargetProcess::get_helper('/Bugs', query)
      results.length
    end

    def self.total_opened(start_date, end_date, team_ids = nil, severities = nil)
      bug_ids = TargetProcess::TeamAssignment::bug_ids_by_team(team_ids, start_date, end_date)

      return 0 if bug_ids.empty?

      query = Query.new
      filter_by_ids(query, bug_ids) unless bug_ids.nil?
      filter_by_severities(query, severities) unless severities.nil?
      filter_out_state(query, 'Not A Bug')

      bugs = 0
      results = TargetProcess::get_helper('/Bugs', query)
      results.each { |it| bugs += 1 }
      bugs
    end

    def self.opened_bug_info(team_ids, start_date, end_date)
      bug_ids = TargetProcess::TeamAssignment::bug_ids_by_team(team_ids, start_date, end_date)

      query = Query.new
      filter_by_ids(query, bug_ids) unless bug_ids.nil?

      results = TargetProcess::get_helper('/Bugs', query)

      results.map { |it|
        name = it['Name']
        story_id = it['UserStory']['Id']
        category_obj = it['CustomFields'].find { |it| it['Name'] == 'Bug Categories' }
        category = category_obj['Value'] if category_obj
        time_spent = it['TimeSpent'].to_i
        "#{TargetProcess::truncate(name)}  (TP-#{story_id} #{category})"
      }
    end

    def self.total_closed(start_date, end_date)
      query = Query.new
      filter_by_end_dates(query, start_date, end_date)
      filter_by_finished(query)

      bugs = 0
      results = TargetProcess::get_helper('/Bugs', query)
      results.each { |it| bugs += 1 }
      bugs
    end

    def self.filter_by_create_dates(query, start_date, end_date)
      query << "(CreateDate gt '#{start_date}')" if start_date
      query << "(CreateDate lt '#{end_date}')" if end_date
    end

    def self.filter_by_end_dates(query, start_date, end_date)
      query << "(EndDate gt '#{start_date}')" if start_date
      query << "(EndDate lt '#{end_date}')" if end_date
    end

    def self.filter_by_finished(query)
      query << "(EntityState.IsFinal eq 'true')"
    end

    def self.filter_by_severities(query, severities)
      query << "(Severity.Name in ('#{severities.join("', '")}'))" unless severities.nil? || severities.empty?
    end

    def self.filter_by_ids(query, ids)
      query << "(Id in ('#{ids.join("', '")}'))" unless ids.nil? || ids.empty?
    end

    def self.filter_by_owner(query, owner_ids)
      query << "(Owner.Id in ('#{owner_ids.join("', '")}'))" unless owner_ids.nil? || owner_ids.empty?
    end

    def self.filter_out_state(query, state)
      query << "(EntityState.Name ne '#{state}')" unless state.nil? || state.empty?
    end
  end
end
