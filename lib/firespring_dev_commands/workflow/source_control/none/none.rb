module Dev
  module Workflow
    module SourceControl
      class None < Base
        attr_accessor :credentials

        def initialize
          @credentials = Credentials.new
        end

        def name
          self.class.name.demodulize
        end
      end
    end
  end
end

module Dev
  module Workflow
    module SourceControl
      class None
        class Credentials < Base
          def active?
            true
          end
        end
      end
    end
  end
end
