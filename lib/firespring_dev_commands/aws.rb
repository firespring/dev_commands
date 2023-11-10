module Dev
  # Class contains base aws constants
  class Aws
    # The config dir for the user's AWS settings
    CONFIG_DIR = "#{Dir.home}/.aws".freeze

    # The default region used if none has been configured in the AWS settings
    DEFAULT_REGION = 'us-east-1'.freeze

    # The default role name used if none has been configured when logging in
    DEFAULT_LOGIN_ROLE_NAME = 'ReadonlyAccessRole'.freeze

    # Runs the query on the client with the parameters
    # Yields each response page
    def self.each_page(client, query, params = {})
      response = client.send(query, params)
      yield response

      while response.next_page? do
        response = response.next_page
        yield response
      end
    end
  end
end
