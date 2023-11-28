module Dev
  class BloomGrowth
    # Class containing user information
    class User
      attr_accessor :data, :id, :type, :name

      def initialize(data)
        @data = data
        @id = data['Id']
        @type = data['Type']
        @name = data['Name'].to_s.strip
      end
    end
  end
end
