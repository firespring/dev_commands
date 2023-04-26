# Load any existing profile if we haven't set one in the environment
require 'dotenv'

module Dev
  class Aws
    # Class containing methods to help write/maintain aws profile information
    class Profile
      # The filename where we store the local profile information
      CONFIG_FILE = "#{Dir.home}/.env.profile".freeze

      # The name of the profile identifier we use
      IDENTIFIER = 'AWS_PROFILE'.freeze

      # Always load the env profile
      Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

      # Retrieve the current profile value
      # Returns nil if one has not been configured
      def current
        ENV.fetch(IDENTIFIER, nil)
      end

      # Write the new profile value to the env file
      def write!(profile)
        override = Dev::Env.new(CONFIG_FILE)
        override.set(IDENTIFIER, profile)
        override.write

        # Update any existing ENV variables
        Dotenv.overload(CONFIG_FILE)
      end

      # Print the profile info for the current account
      def info
        Dev::Aws::Credentials.new.export!
        puts
        puts "  Currently logged in to the #{Dev::Aws::Account.new.name_by_account(current)} (#{current})".light_yellow
        puts
        puts '  To use this profile in your local aws cli, you must either pass the profile as a command line argument ' \
             'or export the corresponding aws variable:'.light_white
        puts "    aws --profile=#{current} s3 ls"
        puts '          -OR-'.light_white
        puts "    export #{IDENTIFIER}=#{current}"
        puts '    aws s3 ls'
        puts
        puts '  To use temporary credentials in your terminal, run the following:'.light_white
        puts "    export AWS_DEFAULT_REGION=#{ENV.fetch('AWS_DEFAULT_REGION', nil)}"
        puts "    export AWS_ACCESS_KEY_ID=#{ENV.fetch('AWS_ACCESS_KEY_ID', nil)}"
        puts "    export AWS_SECRET_ACCESS_KEY=#{ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)}"
        puts "    export AWS_SESSION_TOKEN=#{ENV.fetch('AWS_SESSION_TOKEN', nil)}"
        puts
      end
    end
  end
end
