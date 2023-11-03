module Dev
  module Workflow
    module ContinuousIntegration
      class None < Base
        def initialize
          # Nothing to do here
        end

        def start
          LOG.debug("No #{flow_type} #{__method__} commands have been defined")
        end

        def review
          LOG.debug("No #{flow_type} #{__method__} commands have been defined")
        end

        def finish
          LOG.debug("No #{flow_type} #{__method__} commands have been defined")
        end

        def delete
          LOG.debug("No #{flow_type} #{__method__} commands have been defined")
        end
      end
    end
  end
end
