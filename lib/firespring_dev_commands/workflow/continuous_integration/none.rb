module Dev
  module Workflow
    module ContinuousIntegration
      class None < Base
        def initialize
        end

        def name
          self.class.name
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
