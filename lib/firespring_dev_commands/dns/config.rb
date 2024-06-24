module Dev
  class Aws
    class Dns
      class Config
        # Config object for setting top level config options
        Config = Struct.new(:providers, :nameservers)

        # Instantiates a new top level config object if one hasn't already been created
        # Yields that config object to any given block
        # Returns the resulting config object
        def self.config
          @config ||= Config.new
          yield(@config) if block_given?
          @config
        end

        # Alias the config method to configure for a slightly clearer access syntax
        class << self
          alias_method :configure, :config
        end

        attr_accessor :providers, :nameservers

        # Instantiate a config object
        def initialize
          @providers = self.class.config.providers
          @nameservers = self.class.config.nameservers
        end
      end
    end
  end
end
