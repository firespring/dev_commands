class TargetProcess
  class User
    def self.email_by_id(user_id)
      query = Query.new
      user = TargetProcess::get_helper("/Users/#{user_id}", query)
      user['Email']
    end
  end
end
