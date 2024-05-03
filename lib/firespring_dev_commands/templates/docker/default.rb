require_relative '../base_interface'

module Dev
  module Template
    # Module containing all default docker rake tasks
    module Docker
      # Class containing default rake tasks which are application agnostic
      # This means the commands will be run against all containers in the docker compose file (no service specified)
      class Default < Dev::Template::BaseInterface
        # Create the rake task which runs a docker compose build
        def create_build_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:build)

            desc 'Builds all images used by services in the compose files' \
                 "\n\toptionally specify NO_CACHE=true to not use build cache" \
                 "\n\toptionally specify PULL=true to force pulling new base images"
            task build: %w(init_docker _pre_build_hooks) do
              LOG.debug('In base build')
              Dev::Docker::Compose.new.build
              Rake::Task[:_post_build_hooks].execute
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
            task up: %w(init_docker _pre_up_hooks) do
              LOG.debug('In base up')
              Dev::Docker::Compose.new.up
              Rake::Task[:_post_up_hooks].execute
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
            task logs: %w(init_docker _pre_logs_hooks) do
              LOG.debug('In base logs')
              Dev::Docker::Compose.new.logs
              Rake::Task[:_post_logs_hooks].execute
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
            task down: %w(init_docker _pre_down_hooks) do
              LOG.debug('In base down')
              Dev::Docker::Compose.new.down
              Rake::Task[:_post_down_hooks].execute
            end
          end
        end

        # Create the rake task which stops all running containers
        def create_stop_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:stop)

            desc 'Stops all running containers'
            task stop: %w(init_docker _pre_stop_hooks) do
              LOG.debug('In base stop')

              containers = ::Docker::Container.all(filters: {status: %w(restarting running)}.to_json)
              containers.each do |container|
                next if container&.info&.dig('Names')&.any? { |name| name.start_with?('/windows_tcp') }

                LOG.info "Stopping container #{container.id[0, 12]}"
                container.stop(timeout: 120)
              end

              Rake::Task[:_post_stop_hooks].execute
            end
          end
        end

        # Create the rake task which runs a docker compose restart
        def create_restart_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:restart)

            desc 'Runs a "down" followed by an "up"'
            task restart: %w(init_docker _pre_restart_hooks _pre_down_hooks _pre_up_hooks) do
              LOG.debug('In base restart')
              Dev::Docker::Compose.new.restart
              Rake::Task[:_post_up_hooks].execute
              Rake::Task[:_post_down_hooks].execute
              Rake::Task[:_post_restart_hooks].execute
            end
          end
        end

        # Create the rake task which runs a docker compose clean
        def create_clean_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:clean)

            desc 'Removes all stopped containers and unused images, volumes, and networks'
            task clean: %w(init_docker _pre_clean_hooks) do
              LOG.debug 'In base clean'
              Dev::Docker.new.prune
              LOG.info
              Rake::Task[:_post_clean_hooks].execute
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
            task push: %w(init_docker _pre_push_hooks) do
              LOG.debug 'In base push'
              Dev::Docker::Compose.new.push
              Rake::Task[:_post_push_hooks].execute
            end
          end
        end

        # Create the rake task which runs a docker compose pull
        def create_pull_task!
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            return if exclude.include?(:pull)

            desc 'Pull all images from their defined image repository'
            task pull: %w(init_docker _pre_pull_hooks) do
              LOG.debug 'In base pull'
              Dev::Docker::Compose.new.pull
              Rake::Task[:_post_pull_hooks].execute
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
            task images: %w(init_docker _pre_images_hooks) do
              Dev::Docker.new.print_images
              Rake::Task[:_post_images_hooks].execute
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
            task ps: %w(init_docker _pre_ps_hooks) do
              Dev::Docker.new.print_containers
              Rake::Task[:_post_ps_hooks].execute
            end
          end
        end
      end
    end
  end
end
