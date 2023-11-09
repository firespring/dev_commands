require_relative '../base_interface'

module Dev
  module Template
    # Class contains rake templates for managing upcoming eol dates for configured projects
    class Eol
      class Aws < Dev::Template::BaseInterface
        # Create the rake task for the eol method
        def create_eol_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:eol)

            desc 'Compares the current date to the EOL date for aws resources'
            task eol: %w(init) do
              versions = Dev::EndOfLife::Aws.new.elasticache_products +
                Dev::EndOfLife::Aws.new.lambda_products +
                Dev::EndOfLife::Aws.new.opensearch_products +
                Dev::EndOfLife::Aws.new.rds_products
              Dev::EndOfLife.new(product_versions: versions.compact).check
            end
          end
        end
      end
    end
  end
end
