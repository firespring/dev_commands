module Dev
  class Aws
    class Cloudformation
      # Class which contains Parameters for a Aws cloudformation stack
      class Parameters
        attr_accessor :parameters

        def initialize(parameters = {})
          raise 'parameters should be a hash' unless parameters.is_a?(Hash)

          @parameters = parameters
        end

        # Returns the given parameters in their default format. Can be passed to a create or update command
        def default
          parameters.map { |k, v| {parameter_key: k, parameter_value: v} }
        end

        # Returns the given parameters all set to use the previous values specified in their templates
        def preserve
          parameters.map { |k, _| {parameter_key: k, use_previous_value: true} }
        end
      end
    end
  end
end
