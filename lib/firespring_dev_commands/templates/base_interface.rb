require 'rake/dsl_definition'

module Dev
  # Module containing all available rake template
  module Template
    # Base interface template takes a custom arg for the initializer and requires the user to implement the create_tasks! method
    class BaseInterface
      include ::Rake::DSL

      def initialize(exclude: [])
        @exclude = Array(exclude).map(&:to_sym)
        create_tasks!
      end

      # This method executes all instance methods which match "create_.*_task!"
      # This way a user can easily add new methods to the default template simply by defining new create methods
      # on the class which follow the naming convention
      def create_tasks!
        self.class.instance_methods(false).sort.each do |method|
          next unless /create_.*_task!/.match?(method)

          send(method)
        end
      end
    end
  end
end

module Dev
  module Template
    # Base interface template customized for applications which require a name to be passed in to the constructor
    class ApplicationInterface < Dev::Template::BaseInterface
      include ::Rake::DSL

      def initialize(name, exclude: [])
        @name = name
        super(exclude: exclude)
      end
    end
  end
end

# Create the base init command
DEV_COMMANDS_TOP_LEVEL.instance_eval do
  task :init do
    LOG.debug 'In base init'
  end
end

DEV_COMMANDS_TOP_LEVEL.instance_eval do
  task init_docker: %w(init) do
    LOG.debug 'In base init docker'
  end
end
