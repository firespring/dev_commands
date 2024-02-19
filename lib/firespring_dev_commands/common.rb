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
    # @deprecated Please use {Common#when_confirmed} instead
    def with_confirmation(message, default = 'y', color_message: true)
      message = "\n  #{message}" << '? '.light_green
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

    # Exits unless the user confirms they want to continue
    # If the user answers 'y' then the code will continue
    # All other inputs cause the code to exit
    def exit_unless_confirmed(message, default: nil, colorize: true)
      # If a default is given, it must be y or n
      raise 'invalid default' if default && !%w(y n).include?(default)

      # print the colorized message (if requested) with the default (if given)
      print(confirmation_message(message, default:, colorize:))

      # Default to the default
      # Read from stdin unless non_interactive is set to true
      answer = gather_input(default:)

      return if answer.casecmp('y').zero?

      puts "\n  Cancelled.\n".light_yellow
      exit 1
    end

    # Wraps a block of code in a y/n question
    # If the user answers 'y' then the block is executed
    # All other inputs cause the block to be skipped
    def when_confirmed(message, default: nil, colorize: true)
      # If a default is given, it must be y or n
      raise 'invalid default' if default && !%w(y n).include?(default)

      # print the colorized message (if requested) with the default (if given)
      print(confirmation_message(message, default:, colorize:))

      # Default to the default
      # Read from stdin unless non_interactive is set to true
      answer = gather_input(default:)

      # Yield to the block if confirmed
      yield if answer.casecmp('y').zero?
    end

    # Receive a string from the user on stdin unless non_interactive is set to true
    # If a default value was specified and no answer was given, return the default
    def gather_input(default: nil)
      answer = $stdin.gets.to_s.strip unless ENV['NON_INTERACTIVE'] == 'true'
      answer.to_s.strip
      return default if default && answer.empty?

      answer
    end

    # Build a confirmation message, colorizing each individual part appropriately
    # Include the default value in the message if one was specified
    def confirmation_message(question, default:, colorize:)
      message = conditional_colorize(question, colorize:, color: :light_green)
      options = conditional_colorize('(', colorize:, color: :light_green)
      options << conditional_colorize('y', colorize:, color: :light_yellow)
      options << conditional_colorize('/', colorize:, color: :light_green)
      options << conditional_colorize('n', colorize:, color: :light_yellow)
      options << conditional_colorize(')', colorize:, color: :light_green)

      unless default.to_s.strip.empty?
        options << ' '
        options << conditional_colorize('[', colorize:, color: :light_green)
        options << conditional_colorize(default.to_s.strip, colorize:, color: :light_yellow)
        options << conditional_colorize(']', colorize:, color: :light_green)
      end

      options << conditional_colorize(':', colorize:, color: :light_green)
      "#{message} #{options} "
    end

    # Colorize the string if it has been requested
    def conditional_colorize(string, colorize:, color:)
      return string.send(color) if colorize

      string
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

    # Remove all leading non left-curly-brace characters
    # Remove all trailing non right-curly-brace characters
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

    # Center the string and pad on either side with the given padding character
    def center_pad(string = '', pad: '-', len: 80)
      center_dash = len / 2
      string = string.to_s
      center_str = string.length / 2
      string.rjust(center_dash + center_str - 1, pad).ljust(len - 1, pad)
    end
  end
end
