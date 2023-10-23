class TargetProcess
  class Releases
    def self.total_hotfixes(start_date, end_date)
      query = Query.new
      filter_by_finish_date(query, start_date.to_date, end_date.to_date)

      hotfixes = 0
      results = TargetProcess::get_helper('/Releases', query)
      results.each { |it| hotfixes += 1 if it['Name'] =~ /r\d+-[2-9]/ }
      hotfixes
    end

    def self.filter_by_deploy_date(query, start_date, end_date=nil)
      query << "('CustomFields.Deploy Date' gt '#{start_date}')" if start_date
      query << "('CustomFields.Deploy Date' lt '#{end_date}')" if end_date
    end

    def self.filter_by_finish_date(query, start_date, end_date)
      query << "(EndDate gt '#{start_date}')" if start_date
      query << "(EndDate lt '#{end_date}')" if end_date
    end
  end
end
