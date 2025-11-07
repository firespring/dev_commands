require_relative '../base_interface'

module Dev
  module Template
    module Docker
      # Contains all default rake tasks for a docker application
      class Application < Dev::Template::ApplicationInterface
        # Create the rake task which runs a docker compose build for the application name
        def create_build_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:build)

              desc "Builds the #{application} container"
              task build: %w(init_docker _pre_build_hooks) do
                LOG.debug "In #{application} build"
                Dev::Docker::Compose.new(services: [application]).build
                Rake::Task[:_post_build_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose up for the application name
        def create_up_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:up)

              desc "Starts up the #{application} container and it's dependencies"
              task up: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up"
                Dev::Docker::Compose.new(services: [application]).up
                Rake::Task[:_post_up_hooks].execute
              end

              desc "Starts up the #{application} container and it's dependencies silently"
              task up_silent: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up"
                Dev::Docker::Compose.new(running_silent: true, services: [application]).up
                Rake::Task[:_post_up_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose up --no-deps for the application name
        def create_up_no_deps_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:up_no_deps)

              desc "Starts up the #{application} container but no dependencies"
              task up_no_deps: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up_no_deps"
                Dev::Docker::Compose.new(services: [application], options: ['--no-deps']).up
                Rake::Task[:_post_up_hooks].execute
              end

              desc "Starts up the #{application} container silently but no dependencies"
              task up_no_deps_silent: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up_no_deps_silent"
                Dev::Docker::Compose.new(running_silent: true, services: [application], options: ['--no-deps']).up
                Rake::Task[:_post_up_hooks].execute
              end
            end
          end
        end

        # Create the rake task which starts a docker container for the application name which is not running anything
        def create_up_empty_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:up_empty)

              desc "Starts up an empty #{application} container and it's dependencies"
              task up_empty: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up_empty"
                Dev::Docker::Compose.new(services: [application], options: ['--detach']).run(['sh', '-c', 'while [ true ]; do sleep 300; done;'])
                Rake::Task[:_post_up_hooks].execute
              end

              desc "Starts up an empty #{application} container and it's dependencies silently"
              task up_empty_silent: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up_empty_silent"
                Dev::Docker::Compose.new(running_silent: true, services: [application], options: ['--detach']).run(['sh', '-c', 'while [ true ]; do sleep 300; done;'])
                Rake::Task[:_post_up_hooks].execute
              end
            end
          end
        end

        # Create the rake task which starts a docker container with no dependencies for the application name which is not running anything
        def create_up_empty_no_deps_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:up_empty_no_deps)

              desc "Starts up an empty #{application} container but no dependencies"
              task up_empty_no_deps: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up_empty_no_deps"
                Dev::Docker::Compose.new(services: [application], options: ['--no-deps', '--detach']).run(['sh', '-c', 'while [ true ]; do sleep 300; done;'])
                Rake::Task[:_post_up_hooks].execute
              end

              desc "Starts up an empty #{application} container silently but no dependencies"
              task up_empty_no_deps_silent: %w(init_docker _pre_up_hooks) do
                LOG.debug "In #{application} up_empty_no_deps_silent"
                Dev::Docker::Compose.new(running_silent: true, services: [application],
                                         options: ['--no-deps', '--detach']).run(['sh', '-c', 'while [ true ]; do sleep 300; done;'])
                Rake::Task[:_post_up_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose exec bash for the application name
        def create_sh_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:sh)

              desc "Open a shell into a running #{application} container"
              task sh: %W(init_docker #{application}:up_no_deps _pre_sh_hooks) do
                Dev::Docker::Compose.new(services: [application]).sh
                Rake::Task[:_post_sh_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose logs for the application name
        def create_logs_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:logs)

              desc "Shows logs for the #{application} container"
              task logs: %w(init_docker _pre_logs_hooks) do
                LOG.debug "In #{application} logs"
                Dev::Docker::Compose.new(services: [application]).logs
                Rake::Task[:_post_logs_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose down for the application name
        def create_down_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:down)

              desc "Shut down the #{application} container and remove associated resources"
              task down: %w(init_docker _pre_down_hooks) do
                LOG.debug "In #{application} down"

                # docker-copmose down shuts down everything (you can't only specify a single service)
                # therefore, stop the service manually and prune ununsed resources (just like a down would)
                Dev::Docker::Compose.new(services: [application]).stop
                Dev::Docker.new.prune_containers
                Dev::Docker.new.prune_networks
                Dev::Docker.new.prune_volumes if ENV['REMOVE_VOLUMES'].to_s.strip == 'true'
                Dev::Docker.new.prune_images
                Rake::Task[:_post_down_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose stop for the application name
        def create_stop_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:stop)

              desc "Stops the #{application} container"
              task stop: %w(init_docker _pre_stop_hooks) do
                LOG.debug "In #{application} stop"
                Dev::Docker::Compose.new(services: [application]).stop
                Rake::Task[:_post_stop_hooks].execute
              end
            end
          end
        end

        # Create the rake task which stops, cleans, and starts the application
        def create_restart_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:restart)

              desc "Reloads the #{application} container"
              task restart: %w(init_docker _pre_restart_hooks down up_no_deps) do
                Rake::Task[:_post_restart_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose push for the application name
        def create_push_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:push)

              desc "Push the #{application} container to the configured image repository"
              task push: %w(init_docker _pre_push_hooks) do
                LOG.debug "In #{application} push"
                Dev::Docker::Compose.new(services: [application]).push
                Rake::Task[:_post_push_hooks].execute
              end
            end
          end
        end

        # Create the rake task which runs a docker compose pull for the application name
        def create_pull_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:pull)

              desc "Pull the #{application} container from the configured image repository"
              task pull: %w(init_docker _pre_pull_hooks) do
                LOG.debug "In #{application} pull"
                Dev::Docker::Compose.new(services: [application]).pull
                Rake::Task[:_post_pull_hooks].execute
              end
            end
          end
        end
      end
    end
  end
end
