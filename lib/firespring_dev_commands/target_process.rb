require 'net/http'

module Dev
  class TargetProcess
    CONFIG_FILE = "#{Dir.home}/.env.tp".freeze

    TP_USERNAME = 'TP_USERNAME'.freeze

    TP_PASSWORD = 'TP_PASSWORD'.freeze

    TP_URL = 'TP_URL'.freeze

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

    # Initialize a new jira client using the given inputs
    def initialize(username: self.class.config.username, password: self.class.config.password, url: self.class.config.url)
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

    def user_stories(query, &)
      [].tap do |ary|
        get(UserStory::PATH, query) do |result|
          ary << UserStory.new(result)
        end
        ary.each(&)
      end
    end

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

    def self.parse_dot_net_time(string)
      Time.at(string.slice(6, 10).to_i)
    end

    def self.parse_dot_net_date(string)
      parse_dot_net_time(string).to_date
    end
  end
end
