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
        if Os::windows?
          # Start up a small proxy container if running Docker Desktop on windows
          # This is needed because the docker api library cannot connect to the windows socket
          unless Port::open?('127.0.0.1', 23750)
            puts "Starting local proxy port for docker"
            tmp_compose_file = Tempfile.new('windows_tcp')
            tmp_compose_file.write(WIN_TCP_COMPOSE_CONTENT)
            compose(compose_files: [tmp_compose_file], action: 'up', opts: ['--detach'], project: SecureRandom.hex)
            sleep 1
          end

          # Configure the docker url to use 23750 on windows
          Docker.url = 'tcp://127.0.0.1:23750'

        elsif Os::mac?
          # Set the docker url to point to the user's docker desktop socket
          Docker.url = "unix://#{Dir.home}/.docker/run/docker.sock" unless File.exist?('/var/run/docker.sock')

        elsif Os::nix?
          # Set the docker url to point to the user's docker desktop socket
          Docker.url = "unix://#{Dir.home}/.docker/desktop/docker.sock" unless File.exist?('/var/run/docker.sock')
        end
      end
    end
  end
