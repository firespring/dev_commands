require_relative 'base_interface'

module Dev
  module Template
    # Class contains rake templates for managing configured certificates
    class Certificate < Dev::Template::BaseInterface
      attr_reader :name, :email, :path

      # Allow for custom config path_prefix for the application
      # Allow for custom key parameter path (otherwise base it off the path prefix)
      def initialize(name, email:, path:, exclude: [])
        @name = name
        @email = email
        @path = path

        super(name, exclude:)
      end

      # Create the rake task for the generate method
      def create_generate_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        name = @name
        email = @email
        path = @path
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          return if exclude.include?(:generate)

          desc 'Requests a new certificate for the configured domain using the route53 validation and deposits it in the configured path'
          task certificate: %w(init_docker ensure_aws_credentials) do
            Dev::Docker.new.pull_image('certbot/dns-route53', 'latest')
            c = Dev::Certificate.new(name, email)
            c.request
            c.save(path)
          end
        end
      end
    end
  end
end
