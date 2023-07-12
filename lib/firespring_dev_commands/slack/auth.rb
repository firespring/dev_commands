# Load any existing slack auth if we haven't set one in the environment
require 'dotenv'

module Dev
  class Slack
    class Config
      # The filename where we store the local auth information
      CONFIG_FILE = "#{Dir.home}/.env.slack".freeze

      CLIENT_ID = 'CLIENT_ID'.freeze
      CLIENT_SECRET = 'CLIENT_SECRET'.freeze
      API_TOKEN = 'API_TOKEN'.freeze

      # Always load the env slack auth
      Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

      # Write the new slack auth value to the env file
      def write!(client_id: nil, client_secret: nil, api_token: nil)
        override = Dev::Env.new(CONFIG_FILE)
        override.set(CLIENT_ID, client_id) if client_id
        override.set(CLIENT_SECRET, client_secret) if client_secret
        override.set(API_TOKEN, api_token) if api_token
        override.write

        # Update any existing ENV variables
        Dotenv.overload(CONFIG_FILE)
      end

      # Slack.configure do |c|
      #   c.token = ENV['SLACK_API_TOKEN']
      #   c.logger = LOG
      # end
    end
  end
end
