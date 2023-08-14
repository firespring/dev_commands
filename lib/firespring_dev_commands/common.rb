require 'colorize'

module Dev
  # Class contains several common useful development methods
  class Common
    # Runs a command in a subshell.
    # By default, the subshell is connected to the stdin/stdout/stderr of the current program
    # By default, the current environment is passed to the subshell
    # You can capture the output of the command by setting capture to true
    def run_command(command, stdin: $stdin, stdout: $stdout, stderr: $stderr, env: ENV, capture: false)
      command = Array(command)
      output = nil

      # If capture was specified, write stdout to a pipe so we can return it
      stdoutread, stdout = ::IO.pipe if capture

      # Spawn a subprocess to run the command
      pid = ::Process.spawn(env, *command, in: stdin, out: stdout, err: stderr)

      # Wait for the subprocess to finish and capture the result
      _, result = ::Process.wait2(pid)

      # If capture was specified, close the write pipe, read the output from the read pipe, close the read pipe, and return the output
      if capture
        stdout.close
        output = stdoutread.readlines.join
        stdoutread.close
      end

      # If the exitstatus was non-zero, exit with an error
      unless result.exitstatus.zero?
        puts output if capture
        LOG.error "#{result.exitstatus} exit status while running [ #{command.join(' ')} ]\n".red
        exit result.exitstatus
      end

      output
    end

    # Wraps a block of code in a y/n question.
    # If the user answers 'y' then the block is executed.
    # If the user answers 'n' then the block is skipped.
    def with_confirmation(message, default = 'y', color_message: true)
      message = "\n  #{message}? "
      message = message.light_green if color_message
      print message
      print '('.light_green << 'y'.light_yellow << '/'.light_green << 'n'.light_yellow << ') '.light_green

      answer = default
      answer = $stdin.gets unless ENV['NON_INTERACTIVE'] == 'true'

      unless answer.strip.casecmp('y').zero?
        puts "\n  Cancelled.\n".light_yellow
        exit 1
      end
      puts

      yield
    end

    # Asks for user input using the given message and returns it
    # If a default was specified and the user doesn't give any input, the default will be returned
    def ask(message, default = nil)
      msg = "  #{message}"
      msg << " [#{default}]" if default
      msg << ': '
      print msg
      answer = $stdin.gets.to_s.strip
      return default if default && answer == ''

      answer
    end

    # This method breaks up a string by spaces, however if it finds quoted strings in it,
    # it attempts to preserve those as a single element
    # e.g. "foo 'bin baz' bar" => [foo, 'bin baz', bar]
    def tokenize(str)
      str.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/)
         .reject(&:empty?)
         .map { |s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/, '') }
    end

    # Checks if CODEBUILD_INITIATOR or INITIATOR env variable are set
    # If they are not set, it assumes it is not running in codebuild and return false
    # Otherwise it returns true
    def running_codebuild?
      return false if ENV['CODEBUILD_INITIATOR'].to_s.strip.empty? && ENV['INITIATOR'].to_s.strip.empty?

      true
    end

    # Remove all leading non '{' characters
    # Remove all trailing non '}' characters
    def strip_non_json(str)
      str.sub(/\A[^{]*{/m, '{').sub(/}[^}]*\z/m, '}')
    end

    # Takes two versions and attempts to compare them
    # Returns true if the actual_version is greater than the required version (false otherwise)
    def version_greater_than(required_version, actual_version)
      required_version = required_version.to_s.split('.')
      actual_version = actual_version.to_s.split('.')

      required_version.each_with_index do |required, index|
        required = required.to_i
        actual = actual_version[index].to_i
        return true if actual > required
        next if actual == required

        return false
      end
    end
  end
end
