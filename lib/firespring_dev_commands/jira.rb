require 'jira-ruby'
require 'base64'

module Dev
  # Class which contains methods to conenct to jira and query issues
  class Jira
    # Config object for setting top level jira config options
    # "points_field_name" is the field holding the value for points on a story. If this is not present, all points will default to 0
    # "user_lookup_list" should be an array of Jira::User objects representing the usernames, ids, etc for all jira users
    #    This is a bit clumsy but currently the jira api only returns the user id with issues
    #    and there is no way to query this information from Jira directly.
    Config = Struct.new(:username, :token, :url, :points_field_name, :expand, :user_lookup_list, :read_timeout, :http_debug) do
      def initialize
        self.username = nil
        self.token = nil
        self.url = nil
        self.points_field_name = nil
        self.expand = []
        self.user_lookup_list = []
        self.read_timeout = 120
        self.http_debug = true
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

    attr_accessor :username, :token, :url, :auth, :client

    # Initialize a new jira client using the given inputs
    def initialize(username: self.class.config.username, token: self.class.config.token, url: self.class.config.url)
      @username = username
      @token = token
      @url = url
      @auth = Base64.strict_encode64("#{@username}:#{@token}")

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

      @client = JIRA::Client.new(options)
    end

    # Query jira using the given jql and yield each matching result
    def issues(jql, &)
      start_at = 0
      max_results = 100
      expand = self.class.config.expand

      # Query Jira and yield all issues it returns
      issues = @client.Issue.jql(jql, start_at:, max_results:, expand:)
      issues.map { |data| Issue.new(data) }.each(&)

      # If we returned the max_results then there may be more - add the max results to where we start at and query again
      while issues.length >= max_results
        start_at += max_results
        issues = @client.Issue.jql(jql, start_at:, max_results:, expand:)
        issues.map { |data| Issue.new(data) }.each(&)
      end
    end
  end
end
