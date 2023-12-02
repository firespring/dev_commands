module Dev
  class BloomGrowth
    # Class containing user information
    class User
      attr_accessor :data, :id, :type, :name, :rocks, :direct_reports, :seats

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['Type']
        @name = data['Name'].to_s.strip
        @rocks = nil
        @direct_reports = nil
        @seats = nil
      end

      def rocks
        @rocks ||= [].tap do |ary|
          Dev::BloomGrowth.new.get("/api/v1/rocks/user/#{id}") do |data|
            ary << Rock.new(data)
          end
        end
      end

      def direct_reports
        @direct_reports ||= [].tap do |ary|
          Dev::BloomGrowth.new.get("/api/v1/users/#{id}/directreports") do |data|
            ary << User.new(data)
          end
        end
      end

      def seats
        @seats ||= [].tap do |ary|
          Dev::BloomGrowth.new.get("/api/v1/users/#{id}/seats") do |data|
            ary << Seat.new(data)
            puts ary.last.inspect
          end
        end
      end
    end
  end
end
