require 'colorize'
require 'rake'

# Base rake module
module ::Rake
  # Class override for the execute method
  # This has been added to allow the user to configure whether they want to see a stacktrace
  # when an error has been raised to the top level by rake
  class Task
    # Create an alias method called orig_execute which is a copy of the original execute method
    alias_method :orig_execute, :execute

    # Create a new execute method which runs the original execute and catches any errors it raises
    # Specify STACKTRACE=true or TRACE=true to print the full stack trace of the error
    def execute(args = nil)
      orig_execute(args)
    rescue => e
      # Exception notification stuff
      puts "\n  #{e}\n".light_red
      puts "\n#{e.backtrace.join("\n")}\n" if ENV['STACKTRACE'].to_s.strip == 'true' || ENV['TRACE'].to_s.strip == 'true'
      exit 1
    end
  end
end
