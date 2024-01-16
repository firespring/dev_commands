module Dev
  # Class that contains methods for checking product versions of all tracked projects
  class EndOfLife
    # The URL of the end of life project api
    END_OF_LIFE_API_URL = 'https://endoflife.date/api'.freeze

    # Config object for setting top level git config options
    Config = Struct.new(:check_aws_resources, :product_versions, :manual_dates) do
      def initialize
        self.check_aws_resources = false
        self.product_versions = []
        self.manual_dates = {}
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

    attr_accessor :url, :products, :check_aws_resources, :product_versions

    def initialize(check_aws_resources: self.class.config.check_aws_resources, product_versions: self.class.config.product_versions)
      @check_aws_resources = check_aws_resources
      @product_versions = Array(product_versions)
      raise 'product version must be of type Dev::EndOfLife::ProductVersions' unless @product_versions.all?(Dev::EndOfLife::ProductVersion)
    end

    # Returns all products supported by the EOL api
    def products
      unless @products
        uri = URI.parse("#{END_OF_LIFE_API_URL}/all.json")
        response = Net::HTTP.get_response(uri)
        raise 'unable to query products' unless response.is_a?(Net::HTTPSuccess)

        @products = JSON.parse(response.body)
      end

      @products
    end

    # Prints all of the product version statuses
    # Raises an error if any products are EOL
    def check
      puts
      checks_to_perform = product_versions.clone
      if check_aws_resources
        account_id = Dev::Aws::Profile.new.current
        account_name = Dev::Aws::Account.new.name_by_account(account_id)
        LOG.info "  Current AWS Account is #{account_name} (#{account_id})\n".light_yellow
        checks_to_perform.concat(Dev::EndOfLife::Aws.new.default_products)
      end
      checks_to_perform.sort_by(&:name).each(&:print_status)
      puts
      raise 'found EOL versions' if product_versions.any?(&:eol)
    end
  end
end
