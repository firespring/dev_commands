module Dev
  module Workflow
    module ContinuousIntegration
      class Base
        def initialize
          raise 'not implemented'
        end

        def name
          self.class.name.demodulize
        end

        def flow_type
          self.class.name.deconstantize.demodulize
        end

        def start
          raise 'not implemented'
        end

        def review
          raise 'not implemented'
        end

        def finish
          raise 'not implemented'
        end

        def delete
          raise 'not implemented'
        end
      end
    end
  end
end
