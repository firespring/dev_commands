# Change http timeouts to 1hr
ENV['COMPOSE_HTTP_TIMEOUT'] = '3600'
ENV['DOCKER_BUILDKIT'] = '1'
ENV['COMPOSE_DOCKER_CLI_BUILD'] = '1'

module Dev
  class Docker
    # Class containing methods for interfacing with the docker compose cli
    class Compose
      # Config object for setting top level docker compose config options
      Config = Struct.new(:project_dir, :project_name, :compose_files, :min_version, :max_version) do
        def initialize
          self.project_dir = DEV_COMMANDS_ROOT_DIR
          self.project_name = DEV_COMMANDS_PROJECT_NAME
          self.compose_files = ["#{DEV_COMMANDS_ROOT_DIR}/docker-compose.yml"]
          self.min_version = nil
          self.max_version = nil
        end
      end

      class << self
        # Instantiates a new top level config object if one hasn't already been created
        # Yields that config object to any given block
        # Returns the resulting config object
        def config
          @config ||= Config.new
          yield(@config) if block_given?
          @config
        end

        # Alias the config method to configure for a slightly clearer access syntax
        alias_method :configure, :config

        # Returns the version of the docker-compose executable on the system
        def version
          @version ||= `#{EXECUTABLE_NAME} --version`.match(/version v?([0-9.]+)/)[1]
        end
      end

      # @todo Change this to "docker compose" when everyone is off v1
      # The name of the docker compose executable
      EXECUTABLE_NAME = 'docker-compose'.freeze

      attr_accessor :capture, :compose_files, :environment, :options, :project_dir, :project_name, :services, :user, :volumes

      def initialize(
        compose_files: self.class.config.compose_files,
        environment: [],
        options: [],
        project_dir: self.class.config.project_dir,
        project_name: self.class.config.project_name,
        services: [],
        user: nil,
        volumes: [],
        capture: false
      )
        @compose_files = Array(compose_files)
        @environment = environment
        @options = Array(options)
        @project_dir = project_dir
        @project_name = project_name
        @services = Array(services)
        @user = user
        @volumes = Array(volumes)
        @capture = capture
        check_version
      end

      # Checks the min and max version against the current docker version if they have been configured
      def check_version
        min_version = self.class.config.min_version
        raise "requires #{EXECUTABLE_NAME} version >= #{min_version} (found #{self.class.version})" if min_version &&
                                                                                                       !Dev::Common.new.version_greater_than(min_version, self.class.version)

        max_version = self.class.config.max_version
        raise "requires #{EXECUTABLE_NAME} version < #{max_version} (found #{self.class.version})" if max_version &&
                                                                                                      Dev::Common.new.version_greater_than(max_version, self.class.version)
      end

      # Pull in supported env settings and call build
      # Specify PULL=true to force compose to pull all backing images as part of the build
      # Specify NO_CACHE=true to force compose to build from scratch rather than using build cache
      def build
        merge_options('--parallel')
        merge_env_pull_option
        merge_env_cache_option
        execute_command(build_command('build'))
      end

      # Pull in supported env settings and call up
      # Specify BUILD=true to force/allow service builds before startup
      # Specify NO_DEPS=true to only start the given service and ignore starting it's dependencies
      # Specify DETACHED=false to not detach from the started processes
      def up
        merge_env_build_option
        merge_env_deps_option
        merge_env_detach_option
        execute_command(build_command('up'))
      end

      # Exec into a running container and run the given shell commands
      # Default to running 'bash' which will start a terminal in the running container
      def sh(shell_commands = ['bash'])
        execute_command(build_command('exec', *shell_commands))
      end

      # Pull in supported env settings and call logs
      # Specify NO_FOLLOW=true if you want to print current logs and exist
      # Specify TAIL to pass tail options to the logs command
      def logs
        merge_env_follow_option
        merge_env_tail_option
        execute_command(build_command('logs'))
      end

      # Pull in supported env settings and call down
      # Specify REMOVE_VOLUMES=true to also remove any unused volumes when the containers are stopped
      def down
        merge_env_volumes_option
        execute_command(build_command('down'))
      end

      # Pull in supported env settings and call stop
      def stop
        execute_command(build_command('stop'))
      end

      # Call the compose exec method passing the given args after it
      def exec(*args)
        execute_command(build_command('exec', *args))
      end

      # Call the compose run method passing the given args after it
      def run(*args)
        execute_command(build_command('run', *args))
      end

      # Call the compose push method
      def push
        execute_command(build_command('push'))
      end

      # Call the compose pull method
      def pull
        execute_command(build_command('pull'))
      end

      # Get the first container matching the given name
      # If prefix is specified then this method will filter for compose services in the given project only
      # If status is specified then this method will filter containers in the given status only
      def container_by_name(service_name, prefix = nil, status: [Docker::Status::RUNNING])
        prefix ||= project_name
        containers = ::Docker::Container.all(filters: {status: Array(status), label: ["com.docker.compose.service=#{service_name}"]}.to_json)
        containers.each do |container|
          container&.info&.dig('Names')&.each do |name|
            return container if name.start_with?("/#{prefix}")
          end
        end

        raise "Container not found for #{service_name} with prefix #{prefix}"
      end

      # Gets the dynamic port which was assigned to the compose service on the original private port
      def mapped_public_port(service_name, private_port)
        container = container_by_name(service_name)
        port_mapping = container.info['Ports'].find { |it| it['PrivatePort'] == private_port }
        port_mapping['PublicPort']
      end

      # Merge --no-cache option if nocache is set to true and no existing cache options are present
      private def merge_env_cache_option
        return if @options.any? { |it| it.include?('cache') }

        merge_options('--no-cache') if ENV['NO_CACHE'].to_s.strip == 'true'
      end

      # Merge --pull option if PULL is set to true and no existing pull options are present
      private def merge_env_pull_option
        return if @options.any? { |it| it.include?('pull') }

        merge_options('--pull') if ENV['PULL'].to_s.strip == 'true'
      end

      # Merge --no-build option unless BUILD is set to true and no existing build options are present
      private def merge_env_build_option
        return if @options.any? { |it| it.include?('build') }

        merge_options('--no-build') unless ENV['BUILD'].to_s.strip == 'true'
      end

      # Merge --no-deps option if NO_DEPS is set to true and no existing deps options are present
      private def merge_env_deps_option
        return if @options.any? { |it| it.include?('deps') }

        merge_options('--no-deps') if ENV['NO_DEPS'].to_s.strip == 'true'
      end

      # Merge --detach option unless DETACHED is set to false and no existing detach options are present
      private def merge_env_detach_option
        return if @options.any? { |it| it.include?('detach') }

        merge_options('--detach') unless ENV['DETACHED'].to_s.strip == 'false'
      end

      # Merge -f option unless NO_FOLLOW is set to true and no existing follow options are present
      private def merge_env_follow_option
        return if @options.any? { |it| it.include?('follow') }

        merge_options('-f') unless ENV['NO_FOLLOW'].to_s.strip == 'true'
      end

      # Merge --tail option unless TAIL is empty and no existing tail options are present
      private def merge_env_tail_option
        return if @options.any? { |it| it.include?('tail') }

        merge_options('--tail', ENV.fetch('TAIL', nil)) unless ENV['tail'].to_s.strip.empty?
      end

      # Merge --volumes option if REMOVE_VOLUMES is set to true and no existing volume options are present
      private def merge_env_volumes_option
        return if @options.any? { |it| it.include?('volume') }

        merge_options('--volumes') if ENV['REMOVE_VOLUMES'].to_s.strip == 'true'
      end

      # Merges two arrays removing nested structure and duplicate keys
      private def merge_options(*opts)
        @options = (@options + Array(opts)).flatten.uniq
      end

      # Build the compose command with the given inputs
      private def build_command(action, *cmd)
        command = [EXECUTABLE_NAME]
        command << '--project-directory' << project_dir
        command << '-p' << project_name if project_name
        Array(compose_files).compact.each { |file| command << '-f' << file }
        command << action

        Array(environment).compact.each do |value|
          command << '-e'
          command << normalize_command_line_arg(value)
        end

        Array(volumes).compact.each do |volume|
          command << '-v'
          command << normalize_command_line_arg(volume, ':')
        end

        command << '-u' << user if user
        command.concat(Array(options).compact)
        command.concat(Array(services).compact)
        command.concat(Array(cmd).flatten.compact)
        command
      end

      # Normalize the command line inputs for various complex input possibilities
      # Possible argument types are Array, Hash, or String
      private def normalize_command_line_arg(arg, separator = '=')
        return "#{arg.first}#{separator}#{arg.last}" if arg.is_a?(Array)

        arg.to_s
      end

      # Print the compose command that will be executed and then execute it
      private def execute_command(command)
        LOG.debug " > #{command.join(' ')}"
        ::Dev::Common.new.run_command(command, capture: capture)
      end
    end
  end
end
