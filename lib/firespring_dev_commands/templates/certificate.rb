require_relative 'base_interface'

module Dev
  module Template
    # Class contains rake templates for managing configured certificates
    class Certificate < Dev::Template::BaseInterface
      attr_reader :names, :email, :paths

      def initialize(names, email:, paths:, exclude: [])
        @names = names
        @email = email
        @paths = Array(paths)

        super(exclude:)
      end

      # Create the rake task for the generate method
      def create_generate_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        names = @names
        email = @email
        paths = @paths
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          return if exclude.include?(:generate)

          namespace :certificate do
            desc 'Requests a new certificate for the configured domain using the route53 validation and deposits it in the configured paths'
            task generate: %w(init_docker ensure_aws_credentials) do
              Dev::Docker.new.pull_image('certbot/dns-route53', 'latest')
              c = Dev::Certificate.new(names, email)
              c.request
              paths.each { |path| c.save(path) }
            end
          end
        end
      end
    end
  end
end
