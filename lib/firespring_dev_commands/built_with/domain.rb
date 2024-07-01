module Dev
  class BuiltWith
    class Domain
      attr_accessor :domain, :first, :last, :groups

      def initialize(data)
        @domain = data['domain']
        @first = ::Time.at(data['first'])
        @last = ::Time.at(data['last'])
        @groups = data['groups'].map { |group| Group.new(group) }
      end
    end
  end
end
