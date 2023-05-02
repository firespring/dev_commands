require 'rake/dsl_definition'

module Dev
  # Module containing all available rake template
  module Template
    # Base interface template takes a custom arg for the initializer and requires the user to implement the create_tasks! method
    class BaseInterface
      include ::Rake::DSL

      attr_reader :exclude

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

      attr_reader :name

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

# Create the base init_docker command
DEV_COMMANDS_TOP_LEVEL.instance_eval do
  task init_docker: %w(init) do
    LOG.debug 'In base init docker'
  end
end

# Create the base hook commands
DEV_COMMANDS_TOP_LEVEL.instance_eval do
  # Define an empty _pre_build_hooks handler which can be overridden by the user
  task :_pre_build_hooks do
    # The user may define custom _pre_build_hooks tasks to add any pre-build actions the build process
    # Define this process in the appropriate namespace to add them only to a specific build
    #   In that case it is recommended that you call the base _pre_build_hooks as a dependency of that task
  end

  # Define an empty _post_build_hooks handler which can be overridden by the user
  task :_post_build_hooks do
    # The user may define custom _post_build_hooks tasks to add any post-build actions the build process
    # Define this process in the appropriate namespace to add them only to a specific build
    #   In that case it is recommended that you call the base _post_build_hooks as a dependency of that task
  end

  # Define an empty _pre_up_hooks handler which can be overridden by the user
  task :_pre_up_hooks do
    # The user may define custom _pre_up_hooks tasks to add any pre-up actions the up process
    # Define this process in the appropriate namespace to add them only to a specific up
    #   In that case it is recommended that you call the base _pre_up_hooks as a dependency of that task
  end

  # Define an empty _post_up_hooks handler which can be overridden by the user
  task :_post_up_hooks do
    # The user may define custom _post_up_hooks tasks to add any post-up actions the up process
    # Define this process in the appropriate namespace to add them only to a specific up
    #   In that case it is recommended that you call the base _post_up_hooks as a dependency of that task
  end

  # Define an empty _pre_sh_hooks handler which can be overridden by the user
  task :_pre_sh_hooks do
    # The user may define custom _pre_sh_hooks tasks to add any pre-sh actions the sh process
    # Define this process in the appropriate namespace to add them only to a specific sh
    #   In that case it is recommended that you call the base _pre_sh_hooks as a dependency of that task
  end

  # Define an empty _post_sh_hooks handler which can be overridden by the user
  task :_post_sh_hooks do
    # The user may define custom _post_sh_hooks tasks to add any post-sh actions the sh process
    # Define this process in the appropriate namespace to add them only to a specific sh
    #   In that case it is recommended that you call the base _post_sh_hooks as a dependency of that task
  end

  # Define an empty _pre_logs_hooks handler which can be overridden by the user
  task :_pre_logs_hooks do
    # The user may define custom _pre_logs_hooks tasks to add any pre-logs actions the logs process
    # Define this process in the appropriate namespace to add them only to a specific logs
    #   In that case it is recommended that you call the base _pre_logs_hooks as a dependency of that task
  end

  # Define an empty _post_logs_hooks handler which can be overridden by the user
  task :_post_logs_hooks do
    # The user may define custom _post_logs_hooks tasks to add any post-logs actions the logs process
    # Define this process in the appropriate namespace to add them only to a specific logs
    #   In that case it is recommended that you call the base _post_logs_hooks as a dependency of that task
  end

  # Define an empty _pre_down_hooks handler which can be overridden by the user
  task :_pre_down_hooks do
    # The user may define custom _pre_down_hooks tasks to add any pre-down actions the down process
    # Define this process in the appropriate namespace to add them only to a specific down
    #   In that case it is recommended that you call the base _pre_down_hooks as a dependency of that task
  end

  # Define an empty _post_down_hooks handler which can be overridden by the user
  task :_post_down_hooks do
    # The user may define custom _post_down_hooks tasks to add any post-down actions the down process
    # Define this process in the appropriate namespace to add them only to a specific down
    #   In that case it is recommended that you call the base _post_down_hooks as a dependency of that task
  end

  # Define an empty _pre_stop_hooks handler which can be overridden by the user
  task :_pre_stop_hooks do
    # The user may define custom _pre_stop_hooks tasks to add any pre-stop actions the stop process
    # Define this process in the appropriate namespace to add them only to a specific stop
    #   In that case it is recommended that you call the base _pre_stop_hooks as a dependency of that task
  end

  # Define an empty _post_stop_hooks handler which can be overridden by the user
  task :_post_stop_hooks do
    # The user may define custom _post_stop_hooks tasks to add any post-stop actions the stop process
    # Define this process in the appropriate namespace to add them only to a specific stop
    #   In that case it is recommended that you call the base _post_stop_hooks as a dependency of that task
  end

  # Define an empty _pre_reload_hooks handler which can be overridden by the user
  task :_pre_reload_hooks do
    # The user may define custom _pre_reload_hooks tasks to add any pre-reload actions the reload process
    # Define this process in the appropriate namespace to add them only to a specific reload
    #   In that case it is recommended that you call the base _pre_reload_hooks as a dependency of that task
  end

  # Define an empty _post_reload_hooks handler which can be overridden by the user
  task :_post_reload_hooks do
    # The user may define custom _post_reload_hooks tasks to add any post-reload actions the reload process
    # Define this process in the appropriate namespace to add them only to a specific reload
    #   In that case it is recommended that you call the base _post_reload_hooks as a dependency of that task
  end

  # Define an empty _pre_clean_hooks handler which can be overridden by the user
  task :_pre_clean_hooks do
    # The user may define custom _pre_clean_hooks tasks to add any pre-clean actions the clean process
    # Define this process in the appropriate namespace to add them only to a specific clean
    #   In that case it is recommended that you call the base _pre_clean_hooks as a dependency of that task
  end

  # Define an empty _post_clean_hooks handler which can be overridden by the user
  task :_post_clean_hooks do
    # The user may define custom _post_clean_hooks tasks to add any post-clean actions the clean process
    # Define this process in the appropriate namespace to add them only to a specific clean
    #   In that case it is recommended that you call the base _post_clean_hooks as a dependency of that task
  end

  # Define an empty _pre_push_hooks handler which can be overridden by the user
  task :_pre_push_hooks do
    # The user may define custom _pre_push_hooks tasks to add any pre-push actions the push process
    # Define this process in the appropriate namespace to add them only to a specific push
    #   In that case it is recommended that you call the base _pre_push_hooks as a dependency of that task
  end

  # Define an empty _post_push_hooks handler which can be overridden by the user
  task :_post_push_hooks do
    # The user may define custom _post_push_hooks tasks to add any post-push actions the push process
    # Define this process in the appropriate namespace to add them only to a specific push
    #   In that case it is recommended that you call the base _post_push_hooks as a dependency of that task
  end

  # Define an empty _pre_pull_hooks handler which can be overridden by the user
  task :_pre_pull_hooks do
    # The user may define custom _pre_pull_hooks tasks to add any pre-pull actions the pull process
    # Define this process in the appropriate namespace to add them only to a specific pull
    #   In that case it is recommended that you call the base _pre_pull_hooks as a dependency of that task
  end

  # Define an empty _post_pull_hooks handler which can be overridden by the user
  task :_post_pull_hooks do
    # The user may define custom _post_pull_hooks tasks to add any post-pull actions the pull process
    # Define this process in the appropriate namespace to add them only to a specific pull
    #   In that case it is recommended that you call the base _post_pull_hooks as a dependency of that task
  end

  # Define an empty _pre_images_hooks handler which can be overridden by the user
  task :_pre_images_hooks do
    # The user may define custom _pre_images_hooks tasks to add any pre-images actions the images process
    # Define this process in the appropriate namespace to add them only to a specific images
    #   In that case it is recommended that you call the base _pre_images_hooks as a dependency of that task
  end

  # Define an empty _post_images_hooks handler which can be overridden by the user
  task :_post_images_hooks do
    # The user may define custom _post_images_hooks tasks to add any post-images actions the images process
    # Define this process in the appropriate namespace to add them only to a specific images
    #   In that case it is recommended that you call the base _post_images_hooks as a dependency of that task
  end

  # Define an empty _pre_ps_hooks handler which can be overridden by the user
  task :_pre_ps_hooks do
    # The user may define custom _pre_ps_hooks tasks to add any pre-ps actions the ps process
    # Define this process in the appropriate namespace to add them only to a specific ps
    #   In that case it is recommended that you call the base _pre_ps_hooks as a dependency of that task
  end

  # Define an empty _post_ps_hooks handler which can be overridden by the user
  task :_post_ps_hooks do
    # The user may define custom _post_ps_hooks tasks to add any post-ps actions the ps process
    # Define this process in the appropriate namespace to add them only to a specific ps
    #   In that case it is recommended that you call the base _post_ps_hooks as a dependency of that task
  end
end
