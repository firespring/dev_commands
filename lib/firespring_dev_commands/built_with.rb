module Dev
  # Class for querying target process data from their api
  class BuiltWith
    # The config file to try to load credentials from
    CONFIG_FILE = "#{Dir.home}/.env.builtwith".freeze

    # The api key to use for requests
    API_KEY = 'API_KEY'.freeze

    # The text of the url variable key
    URL = 'URL'.freeze

    # Config object for setting top level target process config options
    Config = Struct.new(:api_key, :url, :http_debug) do
      def initialize
        Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

        self.api_key = ENV.fetch(API_KEY, nil)
        self.url = ENV.fetch(URL, 'https://api.builtwith.com/free1/api.json')
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

    attr_accessor :api_key, :url, :path, :auth, :client, :headers

    # Initialize a new target process client using the given inputs
    def initialize(api_key: self.class.config.api_key, url: self.class.config.url)
      raise 'api_key is required' if api_key.to_s.strip.empty?
      raise 'url is required' if url.to_s.strip.empty?

      @api_key = api_key
      @url = url
      uri = URI.parse(@url)
      @path = uri.path

      @client = Net::HTTP.new(uri.host, uri.port)
      @client.use_ssl = true
      @client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @client.set_debug_output(LOG) if self.class.config.http_debug
      @headers = {}
    end

    def get(domain)
      opts = {KEY: api_key, LOOKUP: domain}
      thing = "#{path}?#{URI.encode_www_form(opts)}"

      response = client.request_get(thing, headers)
      raise "Error querying #{thing}: #{response.inspect}" unless response.response.is_a?(Net::HTTPSuccess)

      parsed_response = JSON.parse(response.body)
      return Domain.new(parsed_response)
    end
  end
end
