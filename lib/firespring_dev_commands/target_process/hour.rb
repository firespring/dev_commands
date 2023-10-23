class TargetProcess
  class Hours
    def self.times_by_user(start_date, end_date)
      query = Query.new
      filter_by_dates(query, start_date, end_date)

      {}.tap { |hsh|
        results = TargetProcess::get_helper('/Times', query)
        results.each { |it|
          key = it['User']['Id']
          hsh[key] ||= 0.0
          hsh[key] += it['Spent'].to_f
        }
      }
    end

    def self.total_time_logged(start_date, end_date, members=nil)
      query = Query.new
      filter_by_dates(query, start_date, end_date)
      filter_by_team_members(query, members) unless members.nil? || members.empty?

      times = 0.0
      results = TargetProcess::get_helper('/Times', query)
      results.each { |it| times += it['Spent'].to_f }
      times
    end

    def self.total_time_logged_per_person(start_date, end_date, members=nil)
      query = Query.new
      filter_by_dates(query, start_date, end_date)
      filter_by_team_members(query, members) unless members.nil? || members.empty?

      results = TargetProcess::get_helper('/Times', query)

      times = {}
      results.each do |it|
        name = "#{it['User']['FirstName']} #{it['User']['LastName']}"
        times[name] ||= {}
        times[name][:time] ||= 0.0
        times[name][:time] += it['Spent'].to_f
        times[name][:name] = name
      end

      values = []
      times.sort_by { |k, v| k }.each { |k, v| values << "#{v[:name]} #{v[:time]}" }
      values
    end

    def self.filter_by_team_members(query, members)
      query << "(User.Id in ('#{members.join("', '")}'))"
    end

    def self.filter_by_dates(query, start_date, end_date)
      query << "(Date gte '#{start_date}')" if start_date
      query << "(Date lte '#{end_date}')" if end_date
    end
  end
end
