module Dev
  module Coverage
    class None < Base
      def php_options
        []
      end

      def check(application: nil)
        puts 'Coverage not checked'
      end
    end
  end
end
