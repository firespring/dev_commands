module Dev
  class Git
    # Class which contains information about the git repository
    class Info
      attr_accessor :name, :path

      def initialize(name, path)
        @name = name
        @path = path
      end
    end
  end
end
