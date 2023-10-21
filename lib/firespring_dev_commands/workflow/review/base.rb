module Dev
  module Workflow
    module Review
      class Base
        def initialize
          raise 'not implemented'
        end

        def name
          self.class.name.demodulize
        end

        def start
          LOG.info("In #{name} start")
        end

        def review
          LOG.info("In #{name} review")
        end

        def finish
          LOG.info("In #{name} finish")
        end

        def delete
          LOG.info("In #{name} delete")
        end
      end
    end
  end
end
