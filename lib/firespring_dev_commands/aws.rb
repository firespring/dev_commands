module Dev
  # Class contains base aws constants
  class Aws
    # The config dir for the user's AWS settings
    CONFIG_DIR = "#{Dir.home}/.aws".freeze

    # The default region used if none have been configured in the AWS settings
    DEFAULT_REGION = 'us-east-1'.freeze
  end
end
