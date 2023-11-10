require 'aws-sdk-ssm'

module Dev
  class Aws
    # Class containing methods for get/put ssm parameters in Aws
    class Parameter
      attr_accessor :client

      def initialize
        @client = ::Aws::SSM::Client.new
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

      # Retrieve all parameters which start with the given path
      def list(path, recursive: true, with_decryption: true)
        [].tap do |ary|
          params = {path: path, recursive: recursive, with_decryption: with_decryption}
          Dev::Aws::each_page(client, :get_parameters_by_path, params) do |response|
            ary.concat(response.parameters)
          end
        end
      end

      # Sets the given parameter name's value to the given value
      # Pass in additional params as desired
      def put(name, value, **params)
        params[:type] ||= 'String'
        params[:overwrite] ||= true
        client.put_parameter(name:, value:, **params)
      end
    end
  end
end
