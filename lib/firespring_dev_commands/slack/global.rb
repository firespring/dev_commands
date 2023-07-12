# Load any existing slack auth if we haven't set one in the environment
require 'dotenv'

module Dev
  class Slack
    class Global
      # The filename where we store the local auth information
      CONFIG_FILE = "#{Dir.home}/.env.slack".freeze

      SLACK_API_TOKEN = 'SLACK_API_TOKEN'.freeze

      def configure
        # Always load the env slack auth
        Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

        ::Slack.configure do |c|
          c.token = ENV['SLACK_API_TOKEN']
          c.logger = LOG
        end
      end
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
