require 'aws-sdk-lambda'

module Dev
  class EndOfLife
    class Aws
      def lambda_products
        client = ::Aws::Lambda::Client.new
        client.list_functions&.functions&.map do |function|
          next unless function.runtime

          name = function.function_name
          product = function.runtime.split(/[0-9]/, 2).first
          version = function.runtime.split(/#{product}/, 2).last.chomp('.x')
          Dev::EndOfLife::ProductVersion.new(product, version, name)
        end.compact
      end

      def unique_lambda_products
      end
    end
  end
end
