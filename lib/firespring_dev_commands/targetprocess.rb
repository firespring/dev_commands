require 'httparty'

module Dev
  class TargetProcess
    CONFIG_FILE = "#{Dir.home}/.env.tp".freeze

    TP_USERNAME = 'TP_USERNAME'.freeze

    TP_PASSWORD = 'TP_PASSWORD'.freeze

    TP_URL = 'TP_URL'.freeze

    Config = Struct.new(:username, :password, :url) do
      def initialize
        self.username = ENV.fetch(TP_USERNAME, nil)
        self.password = ENV.fetch(TP_PASSWORD, nil)
        self.url = ENV.fetch(TP_URL, nil)

        #SBF_PROJECT_ID=217
        #@max_results = 1000
        #@ateam_id = 19003
        #@thundercats_id = 19002
        #@thundercats_current_velocity = 0
        #@design_id = 20749
        #@sbf_qa_id = 20750
        #@sbf_role_id = 10
        #@sbf_projects = ['infrastructure', 'St Baldricks']
        #@tp_api_url = "#{@tp_url}/api/v1"
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

    #include HTTParty

    #base_uri @tp_api_url

    attr_accessor :username, :token, :url, :auth, :client

    # Initialize a new jira client using the given inputs
    def initialize(username: self.class.config.username, password: self.class.config.password, url: self.class.config.url)
      @username = username
      @password = password
      @url = url
      @auth = Base64.strict_encode64("#{@username}:#{@password}")

      options = {
        auth_type: :basic,
        site: @url,
        default_headers: {Authorization: "Basic #{@auth}"},
        context_path: '',
        read_timeout: self.class.config.read_timeout,
        use_ssl: true,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER,
        http_debug: self.class.config.http_debug
      }

      @default_options = {
        basic_auth: {
          username: ENV['TP_USERNAME'],
          password: ENV['TP_PASSWORD']
        },
        headers: {
          'Content-Type' => 'application/json'
        }
      }

      @client = JIRA::Client.new(options)
    end






    def self.max_results
      @max_results
    end

    def self.ateam_id
      @ateam_id
    end

    def self.thundercats_id
      @thundercats_id
    end

    def self.design_id
      @design_id
    end

    def self.sbf_qa_id
      @sbf_qa_id
    end

    def self.sbf_role_id
      @sbf_role_id
    end

    def self.sbf_projects
      @sbf_projects
    end

    def self.get_helper(url, query)
      options = {query: query.generate}
      options.merge!(@default_options)
      response = get(url, options)

      raise "Error querying #{@tp_url} [#{options.inspect}]: #{response.inspect}" unless response.response.is_a?(Net::HTTPOK)
      return response.parsed_response unless response.parsed_response.include?('Items')

      result = response.parsed_response['Items']
      while response['Next'] do
        response = get(response['Next'], @default_options)
        raise "Error querying #{@tp_url}: #{response.inspect}" unless response.response.is_a?(Net::HTTPOK)
        result.concat(response.parsed_response['Items'])
      end

      result
    end

    def self.parse_dot_net_time(string)
      Time.at(string.slice(6, 10).to_i)
    end

    def self.parse_dot_net_date(string)
      parse_dot_net_time(string).to_date
    end

    def self.truncate(string)
      return "#{string[0...37]}..." if string.length > 37
      (string + ' ' * 40)[0, 40]
    end
  end
