module Dev
  class Aws
    # Class containing useful methods for interacting with the Aws account
    class Account
      # Config object for setting top level Aws account config options
      Config = Struct.new(:root, :children, :default, :ecr_registry_ids, :login_to_account_ecr_registry, :default_login_role_name)

      # Instantiates a new top level config object if one hasn't already been created
      # Yields that config object to any given block
      # Returns the resulting config object
      def self.config
        @config ||= Config.new(default_login_role_name: Dev::Aws::DEFAULT_LOGIN_ROLE_NAME)
        yield(@config) if block_given?
        @config
      end

      # Alias the config method to configure for a slightly clearer access syntax
      class << self
        alias_method :configure, :config
      end

      # The name of the file containing the Aws settings
      CONFIG_FILE = "#{Dev::Aws::CONFIG_DIR}/config".freeze

      # Returns the config ini file associated with this object
      def self.config_ini
        IniFile.new(filename: CONFIG_FILE, default: 'default')
      end

      attr_accessor :root, :children, :default, :ecr_registry_ids

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

        # Create the ecr registry list based off several possible configuration values
        @ecr_registry_ids = Array(self.class.config.ecr_registry_ids)
        @ecr_registry_ids << Dev::Aws::Profile.new.current if self.class.config.login_to_account_ecr_registry
        @ecr_registry_ids = @ecr_registry_ids.flatten.compact.reject(&:empty?).uniq
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
        cfgini = self.class.config_ini
        defaultini = cfgini['default']

        region_default = defaultini['region'] || ENV['AWS_DEFAULT_REGION'] || Dev::Aws::DEFAULT_REGION
        defaultini['region'] = Dev::Common.new.ask('Default region name', region_default)

        # NOTE: We had an old config for "mfa_serial" which included the entire arn. We deprecated that config since
        #       it made it much more difficult to switch between different root accounts.
        mfa_name_default = defaultini['mfa_serial']&.split(%r{mfa/})&.last || ENV['AWS_MFA_ARN']&.split(%r{mfa/})&.last || ENV.fetch('USERNAME', nil)
        defaultini['mfa_serial_name'] = Dev::Common.new.ask('Default mfa name', mfa_name_default)
        # TODO: mfa_serial is deprecated. Eventually, we should delete the mfa_serial entry from the config. Leaving it for now
        #       because some projects may be using older versions of the dev_commands library
        # defaultini.delete('mfa_serial')

        session_name_default = defaultini['role_session_name'] || "#{ENV.fetch('USERNAME', nil)}_cli"
        defaultini['role_session_name'] = Dev::Common.new.ask('Default session name', session_name_default)

        duration_default = defaultini['session_duration'] || 36_000
        defaultini['session_duration'] = Dev::Common.new.ask('Default session duration in seconds', duration_default)

        cfgini.write
      end

      # Setup Aws account specific settings
      def setup!(account)
        # Run base setup if it doesn't exist
        Rake::Task['aws:configure:default'].invoke unless File.exist?(CONFIG_FILE) && self.class.config_ini.has_section?('default')

        puts
        puts "Configuring #{account} login values"

        write!(account)
        puts
      end

      # Write Aws account specific settings to the config file
      def write!(account)
        raise 'Configure default account settings first (rake aws:configure:default)' unless File.exist?(CONFIG_FILE)

        # Parse the ini file and load values
        cfgini = self.class.config_ini
        defaultini = cfgini['default']
        profileini = cfgini["profile #{account}"]

        profileini['source_profile'] = account

        region_default = profileini['region'] || defaultini['region'] || ENV['AWS_DEFAULT_REGION'] || Dev::Aws::DEFAULT_REGION
        profileini['region'] = Dev::Common.new.ask('Default region name', region_default)

        # NOTE: Turns out the role_arn is needed by the aws cli so we are changing directions here. Eventually we should remove the role_name
        #       from the ini files and only store the role arn. However we need to still keep the functinoality so that the user is only asked
        #       for the role name - not the entire arn
        role_name_default = if profileini['role_name']
                              profileini['role_name']
                            elsif profileini['role_arn']
                              profileini['role_arn']&.split(%r{role/})&.last
                            else
                              self.class.config.default_login_role_name
                            end
        role_name = Dev::Common.new.ask('Default role name', role_name_default)
        profileini['role_arn'] = "arn:aws:iam::#{account}:role/#{role_name}"
        # TODO: role_name is deprecated. Eventually, we should delete the role_name entry from the config. Leaving it for now
        #       because some projects may be using older versions of the dev_commands library
        # profileini.delete('role_name')

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
