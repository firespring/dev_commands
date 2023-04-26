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
              task build: %w(init_docker) do
                LOG.debug "In #{application} build"
                Dev::Docker::Compose.new(services: [application]).build
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
              task up: %w(init_docker) do
                LOG.debug "In #{application} up"
                Dev::Docker::Compose.new(services: [application]).up
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
              task up_no_deps: %w(init_docker) do
                LOG.debug "In #{application} up_no_deps"
                Dev::Docker::Compose.new(services: [application], options: ['--no-deps']).up
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
              task sh: %W(init_docker #{application}:up) do
                Dev::Docker::Compose.new(services: [application]).sh
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
              task logs: %w(init_docker) do
                LOG.debug "In #{application} logs"
                Dev::Docker::Compose.new(services: [application]).logs
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

              desc "Stops the #{application} container"
              task down: %w(init_docker) do
                LOG.debug "In #{application} down"

                # docker-copmose down shuts down everything (you can't only specify a single service)
                # therefore, stop the service manually and prune ununsed resources (just like a down would)
                Dev::Docker::Compose.new(services: [application]).stop
                Dev::Docker.new.prune_containers
                Dev::Docker.new.prune_networks
                Dev::Docker.new.prune_volumes if ENV['REMOVE_VOLUMES'].to_s.strip == 'true'
                Dev::Docker.new.prune_images
              end
            end
          end
        end

        # Create the rake task which stops, cleans, and starts the application
        def create_reload_task!
          application = @name
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              return if exclude.include?(:reload)

              desc "Reloads the #{application} container"
              task reload: %w(init_docker down up) do
                # Run the down and then the up commands
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
              task push: %w(init_docker) do
                LOG.debug "In #{application} push"
                Dev::Docker::Compose.new(services: [application]).push
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
              task pull: %w(init_docker) do
                LOG.debug "In #{application} pull"
                Dev::Docker::Compose.new(services: [application]).pull
              end
            end
          end
        end
      end
    end
  end
end
