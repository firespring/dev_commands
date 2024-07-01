module Dev
  class BuiltWith
    class Group
      attr_accessor :name, :live, :dead, :latest, :oldest, :categories

      def initialize(data)
        @name = data['name']
        @live = data['live']
        @dead = data['dead']
        @latest = ::Time.at(data['latest'])
        @oldest = ::Time.at(data['oldest'])
        @categories = data['categories'].map { |category| Category.new(category) }
      end
    end
  end
end
