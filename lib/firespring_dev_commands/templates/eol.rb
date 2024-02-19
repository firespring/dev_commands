require_relative 'base_interface'

module Dev
  module Template
    # Class contains rake templates for managing upcoming eol dates for configured projects
    class Eol < Dev::Template::BaseInterface
      # Create the rake task for the eol method
      def create_eol_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          return if exclude.include?(:eol)

          desc 'Compares the current date to the EOL date for all configured projects' \
               "\n\toptionally specify CHECK_AWS=<true/false> to toggle whether AWS resources are checked for EOL (defaults to true)"
          task eol: %w(init) do
            Dev::EndOfLife.new.check
          end
        end
      end
    end
  end
end
