require 'net/http'

module Dev
  # Class for querying target process data from their api
  class TargetProcess
    # The config file to try to load credentials from
    CONFIG_FILE = "#{Dir.home}/.env.tp".freeze

    # The text of the username variable key
    TP_USERNAME = 'TP_USERNAME'.freeze

    # The text of the password variable key
    TP_PASSWORD = 'TP_PASSWORD'.freeze

    # The text of the url variable key
    TP_URL = 'TP_URL'.freeze

    # Config object for setting top level jira config options
    Config = Struct.new(:username, :password, :url, :http_debug) do
      def initialize
        Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

        self.username = ENV.fetch(TP_USERNAME, nil)
        self.password = ENV.fetch(TP_PASSWORD, nil)
        self.url = ENV.fetch(TP_URL, nil)
        self.http_debug = false
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

    attr_accessor :username, :password, :url, :auth, :client, :headers

    # Initialize a new target process client using the given inputs
    def initialize(username: self.class.config.username, password: self.class.config.password, url: self.class.config.url)
      raise 'username is required' if username.to_s.strip.empty?
      raise 'password is required' if password.to_s.strip.empty?
      raise 'url is required' if url.to_s.strip.empty?

      @username = username
      @password = password
      @auth = Base64.strict_encode64("#{@username}:#{@password}")
      @url = url
      uri = URI.parse(@url)
      @client = Net::HTTP.new(uri.host, uri.port)
      @client.use_ssl = true
      @client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @client.set_debug_output(LOG) if self.class.config.http_debug
      @headers = {
        'authorization' => "Basic #{auth}",
        'content-type' => 'application/json',
        'accept' => 'application/json'
      }
    end

    # Perform a query to the release api path
    # Call the given block (if present) with each release
    # Return all releases
    def releases(query, &)
      [].tap do |ary|
        get(Release::PATH, query) do |result|
          ary << Release.new(result)
        end
        ary.each(&)
      end
    end

    # Perform a query to the user story api path
    # Call the given block (if present) with each user story
    # Return all user stories
    def user_stories(query, &)
      [].tap do |ary|
        get(UserStory::PATH, query) do |result|
          ary << UserStory.new(result)
        end
        ary.each(&)
      end
    end

    # Perform a query to the user story history api path
    # Call the given block (if present) with each user story history
    # Return all user stories
    def user_story_histories(query, &)
      [].tap do |ary|
        get(UserStoryHistory::PATH, query) do |result|
          ary << UserStoryHistory.new(result)
        end
        ary.each(&)
      end
    end

    # Perform a query to the team assignments api path
    # Call the given block (if present) with each team assignment
    # Return all team assignments
    def team_assignments(query, &)
      [].tap do |ary|
        get(TeamAssignment::PATH, query) do |result|
          ary << TeamAssignment.new(result)
        end
        ary.each(&)
      end
    end

    # Perform a get request to the given path using the given query
    # Call the given block (if present) with each piece of data
    # Return all pieces of data
    def get(path, query, &)
      query_string = query.generate
      url = "/api/v1/#{path}"
      url << "?#{URI.encode_www_form(query_string)}" unless query_string.empty?

      response = client.request_get(url, headers)
      raise "Error querying #{url} [#{query_string}]: #{response.inspect}" unless response.response.is_a?(Net::HTTPSuccess)

      parsed_response = JSON.parse(response.body)
      return parsed_response unless parsed_response.key?('Items')

      parsed_response['Items'].each(&)

      while parsed_response['Next']
        response = client.request_get(parsed_response['Next'], headers)
        raise "Error querying #{parsed_response['Next']} [#{query_string}]: #{response.inspect}" unless response.response.is_a?(Net::HTTPSuccess)

        parsed_response = JSON.parse(response.body)
        return parsed_response unless parsed_response.key?('Items')

        parsed_response['Items'].each(&)
      end

      nil
    end
  end
end
