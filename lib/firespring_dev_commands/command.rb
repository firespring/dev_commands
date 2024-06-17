# TODO: Add capture option?
#       Need to add output/errput set too

module Dev
  class Command
    # Config object for setting top level docker config options
    Config = Struct.new(:env, :stdin, :stdout, :stderr, :capture, :fail_on_error) do
      def initialize
        self.stdin = $stdin
        self.stdout = $stdout
        self.stderr = $stderr
        self.env = ENV
        # TODO: Add capture option?
        self.fail_on_error = true
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

    attr_accessor :command, :stdin, :stdout, :stderr, :env, :fail_on_error, :retcode

    def initialize(
      command,
      stdin: self.class.config.stdin,
      stdout: self.class.config.stdout,
      stderr: self.class.config.stderro,
      env: self.class.config.env,
      fail_on_error: self.class.config.fail_on_error
    )
      @command = Array(command)
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @env = env
      @fail_on_error = fail_on_error
      @retcode = nil
    end

    # TODO: Update
    # Runs a command in a subshell.
    # By default, the subshell is connected to the stdin/stdout/stderr of the current program
    # By default, the current environment is passed to the subshell
    def run
      # Spawn a subprocess to run the command
      pid = ::Process.spawn(env, *command, in: stdin, out: stdout, err: stderr)

      # Wait for the subprocess to finish and capture the result
      _, result = ::Process.wait2(pid)
      @retcode = result.exitstatus

      # If the exitstatus was non-zero, exit with an error
      unless success?
        LOG.error "#{result.exitstatus} exit status while running [ #{command.join(' ')} ]\n".red
        exit result.exitstatus if fail_on_error
      end

      self
    end

    def success?
      raise 'success? called before command has been run' if retcode.nil?
      retcode.zero?
    end


    def failure?
      raise 'failure? called before command has been run' if retcode.nil?
      retcode.nonzero?
    end
  end
end

