module Dev
  # Class containing methods related to node application
  class Node
    # The default path of the application inside the container
    DEFAULT_PATH = '/usr/src/app'.freeze

    # The default name of the node package file
    DEFAULT_PACKAGE_FILE = 'package.json'.freeze

    # Config object for setting top level git config options
    Config = Struct.new(:container_path, :local_path, :package_file) do
      def initialize
        self.container_path = DEFAULT_PATH
        self.local_path = DEV_COMMANDS_ROOT_DIR
        self.package_file = DEFAULT_PACKAGE_FILE
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
    end

    attr_accessor :container_path, :local_path, :package_file

    def initialize(container_path: nil, local_path: nil, package_file: nil)
      @container_path = container_path || self.class.config.container_path
      @local_path = local_path || self.class.config.local_path
      @package_file = package_file || self.class.config.package_file
    end

    # The base npm command that is the starting point for all subsequent commands
    def base_command
      ['npm', '--prefix', container_path]
    end

    # Build the command which can be use to perform a security audit report
    def audit_command
      audit = base_command
      audit << 'audit'
      audit << '--audit-level=none'
      audit << '--json'
      audit.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      audit << '2>&1' << '||' << 'true'

      # Run the command as part of a shell script
      ['sh', '-c', audit.join(' ')]
    end

    # Build the command to fix any security vulnerabilities that were found
    def audit_fix_command
      audit_fix = base_command
      audit_fix << 'audit' << 'fix'
      audit_fix.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      audit_fix
    end

    # Build the npm install command
    def install_command
      install = base_command
      install << 'install'
      install.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      install
    end

    # Build the node lint command
    def lint_command
      lint = base_command
      lint << 'run' << 'lint'
      lint.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      lint
    end

    # Build the node lint fix command
    def lint_fix_command
      lint_fix = base_command
      lint_fix << 'run' << 'lint-fix'
      lint_fix.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      lint_fix
    end

    # Build the node test command
    def test_command
      test = base_command
      test << 'run' << 'test'
      test.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      test
    end

    # Build the node test (with coverage) command
    def test_coverage_command
      test = base_command
      test << 'run' << 'test:coverage'
      test.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      test
    end
  end
end
