# Load any existing slack auth if we haven't set one in the environment
require 'dotenv'

module Dev
  class Slack
    # A class to manage slack global configuration settings
    class Global
      # The filename where we store the local auth information
      CONFIG_FILE = "#{Dir.home}/.env.slack".freeze

      # The name of the environmental setting which holds the slack token
      SLACK_API_TOKEN = 'SLACK_API_TOKEN'.freeze

      # Method to load the slack config file and then configure slack
      def configure
        # Always load the env slack auth
        Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

        ::Slack.configure do |c|
          c.token = ENV.fetch(SLACK_API_TOKEN, nil)
          c.logger = LOG if ENV['ENABLE_SLACK_DEBUG'].to_s.strip == 'true'
        end
      end

      # Run the configure when creating this class to load any existing settings
      new.configure

      # Write the new slack auth value to the env file
      def write!(api_token)
        override = Dev::Env.new(CONFIG_FILE)
        override.set(SLACK_API_TOKEN, api_token)
        override.write
        configure
      end
    end
  end
end
