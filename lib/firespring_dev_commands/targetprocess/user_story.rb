class TargetProcess
  class UserStory
    def self.total_in_design
      TargetProcess::TeamAssignment.stories_in_progress_by_team([TargetProcess::design_id]).count
    end

    def self.total_in_progress_without_tests
      query = Query.new
      filter_by_project(query, TargetProcess::sbf_projects)
      filter_by_states(query, ['In Progress'])
      filter_by_missing_tests(query)

      TargetProcess::get_helper('/UserStories', query).length
    end

    def self.total_points_consumed(projects, start_date, end_date, team_id = nil)
      query = Query.new
      filter_by_project(query, projects)
      filter_by_final(query)
      filter_by_end_dates(query, start_date, end_date)
      filter_by_assigned_team(query, team_id) unless team_id.nil?

      results = TargetProcess::get_helper('/UserStories', query)
      results.map { |it| it["Effort"] }.reduce(:+) || 0
    end

    def self.stories_finished_by_team(team_ids, start_date, end_date)
      team_finished_story_ids = TargetProcess::TeamAssignment.story_ids_finished_by_team(team_ids, start_date, end_date)

      return [] if team_finished_story_ids.nil? || team_finished_story_ids.empty?

      query = Query.new
      filter_by_user_story_ids(query, team_finished_story_ids)

      TargetProcess::get_helper('/UserStories', query)
    end

    def self.total_points_consumed_by_team(team_ids, start_date, end_date)
      stories_finished_by_team(team_ids, start_date, end_date).map { |it| it["Effort"] }.reduce(:+) || 0
    end

    def self.average_cycle_time(projects, start_date, end_date, team_id = nil)
      query = Query.new
      filter_by_project(query, projects)
      filter_by_final(query)
      filter_by_end_dates(query, start_date, end_date)
      filter_by_assigned_team(query, team_id) unless team_id.nil?

      results = TargetProcess::get_helper('/UserStories', query)

      number_of_stories = 0
      total_cycle_time = 0.0
      results.each do |it|
        number_of_stories += 1
        start_time = TargetProcess.parse_dot_net_time(it['StartDate'])
        end_time = TargetProcess.parse_dot_net_time(it['EndDate'])
        total_cycle_time += (end_time - start_time)
      end

      return 0.0 if total_cycle_time <= 0.0

      (total_cycle_time / number_of_stories) / 60 / 60 / 24
    end

    def self.average_cycle_time_by_team(team_ids, start_date, end_date)
      team_finished_stories = TargetProcess::TeamAssignment.stories_finished_by_team(team_ids, start_date, end_date)
      return 0.0 if team_finished_stories.nil? || team_finished_stories.empty?

      number_of_stories = 0
      total_cycle_time = 0.0
      team_finished_stories.each do |it|
        number_of_stories += 1
        start_time = TargetProcess.parse_dot_net_time(it['StartDate'])
        end_time = TargetProcess.parse_dot_net_time(it['EndDate'])
        total_cycle_time += (end_time - start_time)
      end

      return 0.0 if total_cycle_time <= 0.0

      (total_cycle_time / number_of_stories) / 60 / 60 / 24
    end

    def self.total_exceeding_cycle_time(team_ids, cycle_time, start_date, end_date)
      in_progress_stories = TargetProcess::TeamAssignment.stories_in_progress_by_team(team_ids) || []
      team_finished_stories = TargetProcess::TeamAssignment.stories_finished_by_team(team_ids, start_date, end_date) || []

      number_of_stories = 0
      (team_finished_stories + in_progress_stories).each do |it|
        start_time = TargetProcess.parse_dot_net_time(it['StartDate'])
        end_time = it['EndDate'].nil? ? Date.today.to_time : TargetProcess.parse_dot_net_time(it['EndDate'])
        number_of_stories += 1 if ((end_time - start_time)/ 60 / 60 / 24)  > cycle_time
      end

      number_of_stories
    end

    def self.velocity_by_person(start_date, end_date)
      query = Query.new
      query.include = ['Effort', 'Assignments[GeneralUser]']
      filter_by_final(query)
      filter_by_end_dates(query, start_date, end_date)

      velocity_by_user = {}
      results = TargetProcess::get_helper('/UserStories', query)
      results.each { |it|
        effort = it['Effort'].to_f
        it['Assignments']['Items'].each { |assignment|
          user = assignment['GeneralUser']['Login']
          velocity_by_user[user] ||= 0.0
          velocity_by_user[user] += effort
        }
      }
      Hash[velocity_by_user.sort_by { |k, v| v }]
    end


    def self.average_quarterly_velocity_by_person
      require 'active_support/core_ext/date/calculations'
      average_velocity_by_person = {}
      values = {start: true}
      end_date = Date.today.beginning_of_quarter
      until values.empty?
        start_date = end_date.prev_quarter
        values = TargetProcess::UserStory.velocity_by_person(start_date, end_date)
        values.each do |k, v|
          average_velocity_by_person[k] ||= {}
          average_velocity_by_person[k][:num] ||= 0
          average_velocity_by_person[k][:effort] ||= 0.0

          average_velocity_by_person[k][:num] += 1
          average_velocity_by_person[k][:effort] += v
        end

        end_date = start_date
      end

      sorted_averages = {}
      average_velocity_by_person.keys.sort.each do |k|
        num = average_velocity_by_person[k][:num]
        effort = average_velocity_by_person[k][:effort]
        sorted_averages[k] = effort / num
      end

      sorted_averages.sort_by { |k, v| v }
    end

    def self.in_progress(team_id)
      story_info(team_id, ['In Progress'])
    end

    def self.in_testing(team_id)
      story_info(team_id, ['In Testing'])
    end

    def self.returned(team_id)
      story_info(team_id, ['Returned'])
    end

    def self.story_info(team_id, states)
      stories = TargetProcess::TeamAssignment.stories_in_progress_by_team([team_id])
      user_story_ids = stories.collect {|it| it['Assignable']['Id']}
      user_story_ids.uniq!

      query = Query.new
      filter_by_user_story_ids(query, user_story_ids)
      filter_by_states(query, states)
      results = TargetProcess::get_helper('/UserStories', query)
      format_story_info(results)
    end

    def self.finished_story_info(team_ids, start_date, end_date)
      finished_story_ids = []
      cycle_time_to_story_mappings = {}
      TargetProcess::TeamAssignment.stories_finished_by_team(team_ids, start_date, end_date).each do |it|
        finished_story_ids << it['Assignable']['Id']
        start_time = TargetProcess.parse_dot_net_time(it['StartDate'])
        end_time = TargetProcess.parse_dot_net_time(it['EndDate'])
        cycle_time_to_story_mappings[it['Assignable']['Id']] = end_time - start_time
      end

      return [] if finished_story_ids.empty?

      query = Query.new
      filter_by_user_story_ids(query, finished_story_ids)
      result = TargetProcess::get_helper('/UserStories', query)

      result.map { |it|
        name = it['Name']
        cycle_time = (cycle_time_to_story_mappings[it['Id']] / 60 / 60 / 24).round(1)
        points = it['Effort'].to_i
        time_spent = it['TimeSpent'].to_i
        "#{TargetProcess::truncate(name)}  (#{cycle_time}d/#{points}pts/#{time_spent}hrs)"
      }
    end

    def self.format_story_info(stories)
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

    def self.filter_by_user_story_ids(query, user_story_ids)
      query << "(Id in ('#{user_story_ids.join("', '")}'))"
    end

    def self.filter_by_project(query, projects)
      query << "(Project.Name in ('#{projects.join("', '")}'))"
    end

    def self.filter_by_states(query, states)
      query << "(EntityState.Name in ('#{states.join("', '")}'))" unless states.nil? || states.empty?
    end

    def self.filter_by_final(query)
      query << "(EntityState.IsFinal eq 'true')"
    end

    def self.filter_by_end_dates(query, start_date, end_date)
      query << "(EndDate gt '#{start_date}')" if start_date
      query << "(EndDate lt '#{end_date}')" if end_date
    end

    def self.filter_by_missing_tests(query)
      query << "(LinkedTestPlan is nil)"
    end
  end
end
