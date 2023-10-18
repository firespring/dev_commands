require 'base64'
require 'net/http'

module Dev
  # Class which contains methods to conenct to jira and query issues
  class Jira
    class Issue
      class TimeInStatus
        # The filename where we store the local auth information
        CONFIG_FILE = "#{Dir.home}/.env.tis".freeze

        # The name of the environmental setting which holds the slack token
        JIRA_TIS_TOKEN = 'JIRA_TIS_TOKEN'.freeze

        # The default TimeInStatus api url
        DEFAULT_URL = 'https://tis.obss.io/'

        Config = Struct.new(:token, :url, :http_debug) do
          def initialize
            Dotenv.load(CONFIG_FILE) if File.exist?(CONFIG_FILE)

            self.token = ENV.fetch(JIRA_TIS_TOKEN, nil)
            self.url = DEFAULT_URL
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

        attr_accessor :username, :token, :url, :client

        # Initialize a new jira client using the given inputs
        def initialize(token: self.class.config.token, url: self.class.config.url)
          @token = token
          @url = url

          uri = URI.parse(url)
          @client = Net::HTTP.new(uri.host, uri.port)
          @client.use_ssl = true
          @client.verify_mode = OpenSSL::SSL::VERIFY_PEER
          @client.set_debug_output(LOG) if self.class.config.http_debug
        end

        def headers(addtl_headers = {})
          {Authorization: "TISJWT #{token}"}.merge(addtl_headers)
        end

        def get(path, params: {})
          params = URI.encode_www_form(params)
          response = client.request_get("#{path}?#{params}", headers)

          # Raise an error if we got a non-success from TIS
          raise "error response from TimeInStatus (#{response.code}): #{response.message}" unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body)

          #rescue => e
          #  LOG.error("Error looking up severity for #{cve}: #{e.message}")
          #  LOG.error('WARNING: Unable to determine severity - ignoring with UNKNOWN')
        end

        def list(jql, start_date: '2021-01-01')
          get(
            '/rest/list',
            params: {
              filterType: 'customjql',
              customjql: jql,
              columnsBy: 'statusDuration',
              multiVisitBehavior: 'first',
              startDate: start_date,
              dateRangeField: 'created',
              calendar: 'normalHours',
              dayLength: '24HourDays'
            }
          )
        end

        def issue(key)
          get(
            '/rest/issue',
            params: {
              issueKey: key,
              columnsBy: 'statusDuration',
              calendar: 'normalHours'
            }
          )
        end



        # How do we convert this to objects?
=begin
  "table": {
    "header": {
      "headerColumns": [
        {
          "id": "issuekey",
          "value": "Key"
        },
        {
          "id": "summary",
          "value": "Summary"
        }
      ],
      "groupByColumns": [

      ],
      "fieldColumns": [

      ],
      "valueColumns": [
        {
          "id": "1",
          "value": "Open",
          "isConsolidated": false
        },
        {
          "id": "6",
          "value": "Closed",
          "isConsolidated": false
        }
      ]
    },
    "body": {
      "rows": [
        {
          "headerColumns": [
            {
              "id": "issuekey",
              "value": "FDP-45970"
            },
            {
              "id": "summary",
              "value": "Add cycle time to the dashboards"
            }
          ],
          "groupByColumns": [

          ],
          "fieldColumns": [

          ],
          "valueColumns": [
            {
              "id": "1",
              "value": "10314.3828333333", # minutes
              "raw": "618862970",
              "count": "1"
            },
            {
              "id": "6",
              "value": "10104.07285",
              "raw": "606244371",
              "count": "1"
            }
          ],
          "currentState": [
            {
              "id": "6",
              "value": "10104.07285",
              "raw": "606244371"
            }
          ]
        }
      ]
    }
  }=end




        # TODO: Needs to hit the jira url
        #def status
        #  get('/rest/api/3/status')
        #end

        def calendar
          get('/rest/calendar')
        end
      end
    end
  end
end
