module Dev
  class BloomGrowth
    # Class containing seat information
    class Seat
      attr_accessor :data, :id, :type, :name

      def initialize(data)
        @data = data
        position = data.dig('Group', 'Position')
        @id = position&.fetch('Id')
        @type = position&.fetch('Type')
        @name = position&.fetch('Name').to_s.strip
      end
    end
  end
end
