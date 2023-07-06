require 'aws-sdk-ssm'

module Dev
  class Aws
    # Class containing methods for get/put ssm parameters in Aws
    class Parameter
      attr_accessor :client

      def initialize
        @client = nil
      end

      # Create/set a new client if none is present
      # Return the client
      def client
        @client ||= ::Aws::SSM::Client.new
      end

      # Get the value of the given parameter name
      def get_value(name, with_decryption: true)
        get(name, with_decryption:)&.value
      end

      # Retrieve the ssm parameter object with the given name
      def get(name, with_decryption: true)
        client.get_parameter(name:, with_decryption:)&.parameter
      rescue ::Aws::SSM::Errors::ParameterNotFound
        raise "parameter #{name} does not exist in #{Dev::Aws::Profile.new.current}"
      end
    end
  end
end
