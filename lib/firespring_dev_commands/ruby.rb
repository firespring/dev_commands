module Dev
  # Class containing methods related to ruby application
  class Ruby
    # The default path of the application inside the container
    DEFAULT_PATH = '/usr/src/app'.freeze

    # The default name of the ruby package file
    DEFAULT_PACKAGE_FILE = 'Gemfile'.freeze

    # Config object for setting top level git config options
    Config = Struct.new(:container_path, :local_path, :package_file, :min_version, :max_version, :coverage) do
      def initialize
        self.container_path = DEFAULT_PATH
        self.local_path = DEV_COMMANDS_ROOT_DIR
        self.package_file = DEFAULT_PACKAGE_FILE
        self.coverage = nil
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

      # Returns the version of the ruby executable running on the system
      def version
        @version ||= RUBY_VERSION
      end
    end

    attr_accessor :container_path, :local_path, :package_file, :coverage

    def initialize(container_path: nil, local_path: nil, package_file: nil, coverage: nil)
      @container_path = container_path || self.class.config.container_path
      @local_path = local_path || self.class.config.local_path
      @package_file = package_file || self.class.config.package_file
      @coverage = coverage || Dev::Coverage::None.new
      raise 'coverage must be an instance of the base class' unless @coverage.is_a?(Dev::Coverage::Base)

      check_version
    end

    # Checks the min and max version against the current ruby version if they have been configured
    def check_version
      min_version = self.class.config.min_version
      raise "requires ruby version >= #{min_version} (found #{self.class.version})" if min_version && !Dev::Common.new.version_greater_than(min_version, self.class.version)

      max_version = self.class.config.max_version
      raise "requires ruby version < #{max_version} (found #{self.class.version})" if max_version && Dev::Common.new.version_greater_than(max_version, self.class.version)
    end

    # The base npm command that is the starting point for all subsequent commands
    def base_command
      ['bundle']
    end

    # Build the command which can be use to perform a security audit report
    def audit_command
      audit = base_command
      audit << 'audit' << 'check'
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

    # Build the bundle install command
    def install_command
      install = base_command
      install << 'install'
      install.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      install
    end

    # Build the bundle lint command
    def lint_command
      lint = base_command
      lint << 'exec' << 'rake' << 'lint'
      lint.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      lint
    end

    # Build the bundle lint fix command
    def lint_fix_command
      lint_fix = base_command
      lint_fix << 'exec' << 'rake' << 'lint:fix'
      lint_fix.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      lint_fix
    end

    # Build the bundle test command
    def test_command
      test = base_command
      test << 'exec' << 'rake' << 'test'
      test.concat(coverage.ruby_options) if coverage
      test.concat(Dev::Common.new.tokenize(ENV['OPTS'].to_s))
      test
    end

    # Run the check to ensure code coverage meets the desired threshold
    def check_test_coverage(application:)
      coverage.check(application:)
    end
  end
end
