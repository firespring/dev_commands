module Dev
  class Docker
    class Desktop
      WIN_TCP_COMPOSE_CONTENT = "
---
version: '3.8'
services:
  socat:
    image: alpine/socat
    container_name: windows_tcp
    network_mode: bridge
    ports:
      - 127.0.0.1:23750:2375
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: tcp-listen:2375,reuseaddr,fork unix-connect:/var/run/docker.sock
    restart: always"

      def initialize
        if Dev::Os.new.windows?
          # Start up a small proxy container if running Docker Desktop on windows
          # This is needed because the docker api library cannot connect to the windows socket
          unless Port.new('127.0.0.1', 23750).open?
            LOG.info("Starting local proxy port for docker")

            # Make sure any stopped version of the container are cleaned up
            Dev::Docker.new.prune_containers

            # Write the compose data to a tmp file
            tmp_compose_file = Tempfile.new('windows_tcp')
            tmp_compose_file.write(WIN_TCP_COMPOSE_CONTENT)
            tmp_compose_file.close

            # Start up the container
            Dev::Docker::Compose.new(
              compose_files: tmp_compose_file.path,
              options: ['--detach'],
              project_name: SecureRandom.hex
            ).up
            sleep 1
          end

          # Configure the docker url to use 23750 on windows
          ::Docker.url = 'tcp://127.0.0.1:23750'

        else
          # If a user based socket has been defined, default to that
          ::Docker.url = if File.exist?("/#{Dir.home}/.docker/run/docker.sock")
                         "unix://#{Dir.home}/.docker/run/docker.sock"
                       elsif File.exist?("/#{Dir.home}/.docker/desktop/docker.sock")
                         "unix://#{Dir.home}/.docker/desktop/docker.sock"
                       end
        end
      end
    end
  end
end
