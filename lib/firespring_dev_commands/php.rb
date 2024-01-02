module Dev
  # Class containing methods related to php applicatio
  class Php
    # The default path of the application inside the container
    DEFAULT_PATH = '/usr/src/app'.freeze

    # The default name of the php package file
    DEFAULT_PACKAGE_FILE = 'composer.json'.freeze

    # Config object for setting top level git config options
    Config = Struct.new(:container_path, :local_path, :package_file, :coverage) do
      def initialize
        self.container_path = DEFAULT_PATH
        self.local_path = DEV_COMMANDS_ROOT_DIR
        self.package_file = DEFAULT_PACKAGE_FILE
        self.coverage = nil
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

    attr_accessor :container_path, :local_path, :package_file, :coverage

    def initialize(container_path: nil, local_path: nil, package_file: nil, coverage: nil)
      @container_path = container_path || self.class.config.container_path
      @local_path = local_path || self.class.config.local_path
      @package_file = package_file || self.class.config.package_file
      @coverage = coverage || Dev::Coverage::None.new
    end

    # The base npm command that is the starting point for all subsequent commands
    def base_command
      ['composer', '--working-dir', container_path]
    end

    # Build the command which can be use to perform a security audit report
    def audit_command
      audit = base_command
      audit << 'audit'
      audit << '--no-interaction'
      audit << '--no-cache'
      audit << '--format' << 'json'
      audit.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      audit << '2>&1' << '||' << 'true'

      # Run the command as part of a shell script
      ['sh', '-c', audit.join(' ')]
    end

    # Build the command to fix any security vulnerabilities that were found
    # def audit_fix_command
    #  audit_fix = base_command
    #  audit_fix << 'audit' << 'fix'
    #  audit_fix.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
    #  audit_fix
    # end

    # Build the php install command
    def install_command
      install = base_command
      install << 'install'
      install.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      install
    end

    # Build the php lint command
    def lint_command
      lint = base_command
      lint << 'lint'
      lint.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      lint
    end

    # Build the php lint fix command
    def lint_fix_command
      lint_fix = base_command
      lint_fix << 'lint-fix'
      lint_fix.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      lint_fix
    end

    # Build the php test command
    def test_command
      test = []
      test << './vendor/bin/phpunit'
      test.concat(coverage.php_options) if coverage
      test.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      test
    end

    # Run the check to ensure code coverage meets the desired threshold
    def check_test_coverage(application:)
      coverage.check(application:)
    end

    # Build the php fast test command
    def test_fast_command(processes = 4)
      test = []
      test << './vendor/bin/paratest'
      test.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      test << "-p#{processes}" << '--runner=WrapperRunner'
      test
    end
  end
end
