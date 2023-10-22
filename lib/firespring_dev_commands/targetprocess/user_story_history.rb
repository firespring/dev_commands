class TargetProcess
  class UserStoryHistory
    def self.total_returned(start_date, end_date, team_id = nil)
      query = Query.new
      filter_by_project(query, TargetProcess::sbf_projects)
      filter_by_states(query, ['Returned'])
      filter_by_dates(query, start_date, end_date)

      stories = TargetProcess::get_helper('/UserStoryHistories', query)

      user_story_ids = stories.collect {|it| it['UserStory']['Id']}
      user_story_ids.uniq!

      return 0 if user_story_ids.empty?

      team_stories = TargetProcess::TeamAssignment::stories_filtered_by_team([team_id], user_story_ids)
      team_stories.uniq {|it| it['Id']}.length
    end

    def self.average_cycle_time_in_testing(start_date, end_date, team_id)
      user_story_ids = TargetProcess::TeamAssignment::story_ids_finished_by_team([team_id], start_date, end_date)

      query = Query.new
      filter_by_states(query, ['In Testing', 'QA Pending'])
      filter_by_stories(query, user_story_ids)

      histories = TargetProcess::get_helper('/UserStoryHistories?orderByAsc=Date', query)

      filtered_histories = {}
      histories.each do |it|
        id = it['UserStory']['Id']
        filtered_histories[id] = {} unless filtered_histories.key?(id)
        if it['EntityState']['Name'] == 'In Testing'
          filtered_histories[id]['StartDate'] = it['Date'] if filtered_histories[id]['StartDate'].nil?
        else
          filtered_histories[id]['EndDate'] = it['Date'] if filtered_histories[id]['EndDate'].nil?
        end
      end

      number_of_stories = 0
      total_cycle_time = 0.0
      filtered_histories.each do |_id, it|
        next if it['StartDate'].nil? || it['EndDate'].nil?
        number_of_stories += 1
        start_time = TargetProcess.parse_dot_net_time(it['StartDate'])
        end_time = TargetProcess.parse_dot_net_time(it['EndDate'])
        total_cycle_time += (end_time - start_time)
      end

      return 0.0 if total_cycle_time <= 0.0

      (total_cycle_time / number_of_stories) / 60 / 60 / 24
    end

    def self.filter_by_story(query, story_id)
      query << "(UserStory.Id eq #{story_id})"
    end

    def self.filter_by_stories(query, story_ids)
      query << "(UserStory.Id in ('#{story_ids.join("', '")}'))" unless story_ids.nil? || story_ids.empty?
    end

    def self.filter_by_project(query, projects)
      query << "(Project.Name in ('#{projects.join("', '")}'))"
    end

    def self.filter_by_states(query, states)
      query << "(EntityState.Name in ('#{states.join("', '")}'))" unless states.nil? || states.empty?
    end

    def self.filter_by_dates(query, start_date, end_date)
      query << "(Date gt '#{start_date}')" if start_date
      query << "(Date lt '#{end_date}')" if end_date
    end
  end
end
