require_relative '../base_interface'

module Dev
  module Template
    # Module containing all default docker rake tasks
    module Docker
      # Class containing default rake tasks which are application agnostic (run against all containers)
      class Default < Dev::Template::BaseInterface
        # Create the rake task which runs a docker compose build
        def create_build_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:build)

            desc 'Builds all images used by services in the compose files' \
                 "\n\toptionally specify NO_CACHE=true to not use build cache" \
                 "\n\toptionally specify PULL=true to force pulling new base images"
            task build: %w(init_docker) do
              LOG.debug('In base build')
              Dev::Docker::Compose.new.build
            end
          end
        end

        # Create the rake task which runs a docker compose up
        def create_up_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:up)

            desc 'Starts containers for all services listed in the compose files' \
                 "\n\toptionally specify DETACHED=false to not detach from the started services"
            task up: %w(init_docker) do
              LOG.debug('In base up')
              Dev::Docker::Compose.new.up
            end
          end
        end

        # Create the rake task which runs a docker compose logs
        def create_logs_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:logs)

            desc 'Connects to the output stream of all running containers' \
                 "\n\toptionally specify NO_FOLLOW=true to print all current output and exit" \
                 "\n\toptionally specify TAIL=n to print the last 'n' lines of output"
            task logs: %w(init_docker) do
              LOG.debug('In base logs')
              Dev::Docker::Compose.new.logs
            end
          end
        end

        # Create the rake task which runs a docker compose down
        def create_down_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:down)

            desc 'Stops and removes containers and associated resources' \
                 "\n\toptionally specify REMOVE_VOLUMES=true to also remove unused volumes"
            task down: %w(init_docker) do
              LOG.debug('In base down')
              Dev::Docker::Compose.new.down
            end
          end
        end

        # Create the rake task which runs a docker compose down followed by an up
        def create_reload_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:reload)

            desc 'Runs a "down" followed by an "up"'
            task reload: %w(down up) do
              LOG.debug('In reload')
            end
          end
        end

        # Create the rake task which runs a docker compose clean
        def create_clean_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:clean)

            desc 'Removes all stopped containers and unused images, volumes, and networks'
            task clean: %w(init_docker) do
              LOG.debug 'In base clean'
              Dev::Docker.new.prune
              LOG.info
            end
            task prune: [:clean] do
              # This is an alias to the clean command
            end
          end
        end

        # Create the rake task which runs a docker compose push
        def create_push_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:push)

            desc 'Push all local images to their defined image repository'
            task push: %w(init_docker) do
              LOG.debug 'In base push'
              Dev::Docker::Compose.new.push
            end
          end
        end

        # Create the rake task which runs a docker compose pull
        def create_pull_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:pull)

            desc 'Pull all images from their defined image repository'
            task pull: %w(init_docker) do
              LOG.debug 'In base pull'
              Dev::Docker::Compose.new.pull
            end
          end
        end

        # Create the rake task which shows all docker images on the system
        def create_images_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:images)

            desc 'Print a table of all images' \
                 "\n\t(equivalent to docker images)"
            task images: %w(init_docker) do
              Dev::Docker.new.print_images
            end
          end
        end

        # Create the rake task which shows all docker containers on the system
        def create_ps_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:ps)

            desc 'Print a table of all running containers' \
                 "\n\t(equivalent to docker ps)"
            task ps: %w(init_docker) do
              Dev::Docker.new.print_containers
            end
          end
        end

        # Create the rake task which shows all docker images on the system
        def create_images_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            unless exclude.include?(:images)
              desc 'Print a table of all images' \
                   "\n\t(equivalent to docker images)"
              task images: [:init] do
                Dev::Docker.new.print_images
              end
            end
          end
        end

        # Create the rake task which shows all docker containers on the system
        def create_ps_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            unless exclude.include?(:ps)
              desc 'Print a table of all running containers' \
                   "\n\t(equivalent to docker ps)"
              task ps: [:init] do
                Dev::Docker.new.print_containers
              end
            end
          end
        end
      end
    end
  end
end
