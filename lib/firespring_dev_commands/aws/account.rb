module Dev
  class Aws
    # Class containing useful methods for interacting with the Aws account
    class Account
      # Config object for setting top level Aws account config options
      Config = Struct.new(:root, :children, :default, :registry)

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

      # The name of the file containing the Aws settings
      CONFIG_FILE = "#{Dev::Aws::CONFIG_DIR}/config".freeze

      attr_accessor :root, :children, :default, :registry

      # Instantiate an account object
      # Requires that root account and at least one child account have been configured
      # All accounts must be of type Dev::Aws::Account::Info
      # If a registry is configured then the user will be logged in to ECR when they log in to the account
      def initialize
        raise 'Root account must be configured' unless self.class.config.root.is_a?(Dev::Aws::Account::Info)
        raise 'Child accounts must be configured' if self.class.config.children.empty? || !self.class.config.children.all?(Dev::Aws::Account::Info)

        @root = self.class.config.root
        @children = self.class.config.children
        @default = self.class.config.default
        @registry = self.class.config.registry
      end

      # Returns all configured account information objects
      def all
        @all ||= ([root] + children).sort_by(&:name)
      end

      # Returns the name portion of all configured account information objects
      def all_names
        @all_names ||= all.map(&:name)
      end

      # Returns the id portion of all configured account information objects
      def all_accounts
        @all_accounts ||= all.map(&:id)
      end

      # Look up the account name for the given account id
      def name_by_account(account)
        all.find { |it| it.id == account }&.name
      end

      # Setup base Aws settings
      def base_setup!
        # Make the base config directory
        FileUtils.mkdir_p(Dev::Aws::CONFIG_DIR)

        puts
        puts 'Configuring default login values'

        # Write region and mfa serial to config file
        cfgini = IniFile.new(filename: "#{Dev::Aws::CONFIG_DIR}/config", default: 'default')
        defaultini = cfgini['default']

        region_default = defaultini['region'] || ENV['AWS_DEFAULT_REGION'] || Dev::Aws::DEFAULT_REGION
        defaultini['region'] = Dev::Common.new.ask('Default region name', region_default)

        mfa_default = defaultini['mfa_serial'] || ENV['AWS_MFA_ARN'] || "arn:aws:iam::#{root}:mfa/#{ENV.fetch('USERNAME', nil)}"
        defaultini['mfa_serial'] = Dev::Common.new.ask('Default mfa arn', mfa_default)

        session_name_default = defaultini['role_session_name'] || "#{ENV.fetch('USERNAME', nil)}_cli"
        defaultini['role_session_name'] = Dev::Common.new.ask('Default session name', session_name_default)

        duration_default = defaultini['session_duration'] || 36_000
        defaultini['session_duration'] = Dev::Common.new.ask('Default session duration in seconds', duration_default)

        cfgini.write
      end

      # Setup Aws account specific settings
      def setup!(account)
        # Run base setup if it doesn't exist
        Rake::Task['aws:configure:default'].invoke unless File.exist?(CONFIG_FILE)

        puts
        puts "Configuring #{account} login values"

        write!(account)
        puts
      end

      # Write Aws account specific settings to the config file
      def write!(account)
        raise 'Configure default account settings first (rake aws:configure:default)' unless File.exist?(CONFIG_FILE)

        # Parse the ini file and load values
        cfgini = IniFile.new(filename: CONFIG_FILE, default: 'default')
        defaultini = cfgini['default']
        profileini = cfgini["profile #{account}"]

        profileini['source_profile'] = account

        region_default = profileini['region'] || defaultini['region'] || ENV['AWS_DEFAULT_REGION'] || Dev::Aws::DEFAULT_REGION
        profileini['region'] = Dev::Common.new.ask('Default region name', region_default)

        role_default = profileini['role_arn'] || "arn:aws:iam::#{account}:role/ReadonlyAccessRole"
        profileini['role_arn'] = Dev::Common.new.ask('Default role arn', role_default)

        cfgini.write
      end

      # Menu to select one of the Aws child accounts
      def select
        # If there is only one child account, use that
        return children.first.id if children.length == 1

        # Output a list for the user to select from
        puts 'Account Selection:'
        children.each_with_index do |account, i|
          printf "  %2s) %-20s    %s\n", i + 1, account.name, account.id
        end
        selection = Dev::Common.new.ask('Enter the number of the account you wish to log in to', select_default)
        number = selection.to_i
        raise "Invalid selection: #{selection}" if number < 1

        # If the selection is 3 characters or more, assume they entered the full account number
        if selection.length > 3
          raise "Invalid selection: #{selection}" unless all_accounts.include?(selection)

          return selection
        end

        # Otherwise they probably entered the number of the account to use
        # Use the number as the index for lookup in accounts array and then get the value of that number
        raise "Invalid selection: #{selection}" unless children.length >= number

        children[number - 1].id
      end

      # Method of determining what the appropriate default account is for the select menu
      # Filters out the account you are currently logged in to if it's no longer
      # an option on the project you are currently trying to login on
      def select_default
        # If we are currently logged in to one of the configured accounts, use it as the default
        account_id = Dev::Env.new(Dev::Aws::Profile::CONFIG_FILE).get(Dev::Aws::Profile::IDENTIFIER)
        return account_id if all_accounts.include?(account_id)

        # Otherwise, if a default is configured, use that
        return default if default

        # Otherwise, just return the first account
        children.first.id
      end
    end
  end
end
