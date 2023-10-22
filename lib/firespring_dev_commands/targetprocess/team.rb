class TargetProcess
  class Team
    def self.member_user_ids(team_ids, role_ids = nil)
      query = Query.new
      filter_by_team_id(query, team_ids)
      filter_by_role_ids(query, role_ids)

      results = TargetProcess::get_helper("/TeamMembers", query)
      results.map { |it| it['User']['Id'] }
    end

    def self.filter_by_team_id(query, team_ids)
      team_ids = Array(team_ids)
      query << "(Team.Id in ('#{team_ids.join("', '")}'))" unless team_ids.nil? || team_ids.empty?
    end

    def self.filter_by_role_ids(query, role_ids)
      query << "(Role.Id in ('#{role_ids.join("', '")}'))" unless role_ids.nil? || role_ids.empty?
    end
  end
end
