require 'net/http'

module Dev
  # Class for interacting with the Bloom Growth api
  class BloomGrowth
    # The config file to try to load credentials from
    CONFIG_FILE = "#{Dir.home}/.env.bloom".freeze

    # The text of the username variable key
    BLOOM_USERNAME = 'BLOOM_USERNAME'.freeze

    # The text of the password variable key
    BLOOM_PASSWORD = 'BLOOM_PASSWORD'.freeze

    # The text of the token variable key
    BLOOM_TOKEN = 'BLOOM_TOKEN'.freeze

    # The text of the url variable key
    BLOOM_URL = 'BLOOM_URL'.freeze

    # Config object for setting top level bloom growth config options
    Config = Struct.new(:username, :password, :url, :http_debug) do
      def initialize
        Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

        self.username = ENV.fetch(BLOOM_USERNAME, nil)
        self.password = ENV.fetch(BLOOM_PASSWORD, nil)
        self.url = ENV.fetch(BLOOM_URL, 'https://app.bloomgrowth.com')
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

    attr_accessor :username, :password, :url, :token, :client, :default_headers

    # Initialize a new target process client using the given inputs
    def initialize(username: self.class.config.username, password: self.class.config.password, url: self.class.config.url)
      raise 'username is required' if username.to_s.strip.empty?
      raise 'password is required' if password.to_s.strip.empty?
      raise 'url is required' if url.to_s.strip.empty?

      @username = username
      @password = password
      @url = url
      uri = URI.parse(@url)
      @client = Net::HTTP.new(uri.host, uri.port)
      @client.use_ssl = true
      @client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @client.set_debug_output(LOG) if self.class.config.http_debug
      @default_headers = {
        'authorization' => "Bearer #{token}",
        'content-type' => 'application/json',
        'accept' => 'application/json'
      }
    end

    # Method for getting a bearer token for the bloom growth api. There are a couple of possible logic paths
    #   - If a token has already been defined, use it
    #   - If a token is found in the ENV, use it
    #   - Otherwise, use the username and passowrd that has been configured to request a new token from bloom
    def token
      @token ||= ENV.fetch(BLOOM_TOKEN, nil)

      unless @token
        response = post(
          '/Token',
          {
            grant_type: 'password',
            userName: username,
            password:
          },
          headers: {
            'content-type' => 'application/json',
            'accept' => 'application/json'
          }
        )
        # TODO: Should we look at https://github.com/DannyBen/lightly for caching the token?
        @token = ENV[BLOOM_TOKEN] = response['access_token']
        LOG.info("Retrieved BloomGrowth token. Expires on #{Time.now + response['expires_in']}")
      end

      @token
    end

    # Return all user objects visible to the logged in user
    def visible_users(&)
      [].tap do |ary|
        get('/api/v1/users/mineviewable') do |user_data|
          ary << User.new(user_data)
        end
        ary.each(&)
      end
    end

    # Perform a get request to the given path using the given query
    # Call the given block (if present) with each piece of data
    # Return all pieces of data
    def get(path, query_string: nil, headers: default_headers, &)
      url = path
      url << "?#{URI.encode_www_form(query_string)}" unless query_string.to_s.strip.empty?

      response = client.request_get(url, headers)
      raise "Error querying #{url} [#{query_string}]: #{response.inspect}" unless response.response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body).each(&)
      nil
    end

    # Perform a post request to the given path using the gien data
    # Return the parsed json body
    def post(path, data, headers: default_headers)
      data = data.to_json unless data.is_a?(String)
      response = client.request_post(path, data, headers)
      raise "Error querying #{url}/#{path}: #{response.inspect}" unless response.response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
