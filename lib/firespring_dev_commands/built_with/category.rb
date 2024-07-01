module Dev
  class BuiltWith
    class Category
      attr_accessor :name, :live, :dead, :latest, :oldest

      def initialize(data)
        @name = data['name']
        @live = data['live']
        @dead = data['dead']
        @latest = ::Time.at(data['latest'])
        @oldest = ::Time.at(data['oldest'])
      end
    end
  end
end
