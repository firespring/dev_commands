require_relative '../../base_interface'

module Dev
  module Template
    module Docker
      # Module for rake tasks associated with ruby applications
      module Ruby
        # Class for default rake tasks associated with a ruby project
        class Application < Dev::Template::ApplicationInterface
          attr_reader :ruby, :start_container_dependencies_on_test

          # Create the templated rake tasks for the ruby application
          #
          # @param application [String] The name of the application
          # @param container_path [String] The path to the application inside of the container
          # @param local_path [String] The path to the application on your local system
          # @param start_container_dependencies_on_test [Boolean] Whether or not to start up container dependencies when running tests
          def initialize(
            application,
            container_path: nil,
            local_path: nil,
            start_container_dependencies_on_test: true,
            exclude: []
          )
            @ruby = Dev::Ruby.new(container_path:, local_path:)
            @start_container_dependencies_on_test = start_container_dependencies_on_test
            super(application, exclude:)
          end

          # Create the rake task which runs linting for the application name
          # rubocop:disable Metrics/MethodLength
          def create_lint_task!
            application = @name
            ruby = @ruby
            exclude = @exclude
            return if exclude.include?(:lint)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all linting software'
                task lint: %w(ruby:lint) do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :lint do
                  desc 'Run all linting software and apply all available fixes'
                  task fix: %w(ruby:lint:fix) do
                    # This is just a placeholder to execute the dependencies
                  end
                end

                namespace :ruby do
                  desc "Run the ruby linting software against the #{application}'s codebase"
                  task lint: %w(init_docker up_no_deps) do
                    LOG.debug("Check for ruby linting errors in the #{application} codebase")

                    options = []
                    options << '-T' if Dev::Common.new.running_codebuild?
                    Dev::Docker::Compose.new(services: application, options:).exec(*ruby.lint_command)
                  end

                  namespace :lint do
                    desc "Run the ruby linting software against the #{application}'s codebase and apply all available fixes"
                    task fix: %w(init_docker up_no_deps) do
                      LOG.debug("Check and fix all ruby linting errors in the #{application} codebase")

                      options = []
                      options << '-T' if Dev::Common.new.running_codebuild?
                      Dev::Docker::Compose.new(services: application, options:).exec(*ruby.lint_fix_command)
                    end
                  end
                end
              end
            end
          end
          # rubocop:enable Metrics/MethodLength

          # Create the rake task which runs all tests for the application name
          def create_test_task!
            application = @name
            ruby = @ruby
            exclude = @exclude
            up_cmd = @start_container_dependencies_on_test ? :up : :up_no_deps
            return if exclude.include?(:test)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all tests'
                task test: [:'ruby:test'] do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :ruby do
                  desc "Run all ruby tests against the #{application}'s codebase"
                  task test: %W(init_docker #{up_cmd}) do
                    LOG.debug("Running all ruby tests in the #{application} codebase")

                    options = []
                    options << '-T' if Dev::Common.new.running_codebuild?
                    Dev::Docker::Compose.new(services: application, options:).exec(*ruby.test_command)
                  end
                end
              end
            end
          end

          # Create the rake task which runs the install command for the application packages
          def create_install_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            application = @name
            ruby = @ruby
            exclude = @exclude
            return if exclude.include?(:install)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                namespace :ruby do
                  desc 'Install all bundled gems'
                  task install: %w(init_docker up_no_deps) do
                    Dev::Docker::Compose.new(services: application).exec(*ruby.install_command)
                  end
                end
              end
            end
          end

          # Create the rake task which runs the security audits for the application packages
          def create_audit_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            application = @name
            ruby = @ruby
            exclude = @exclude
            return if exclude.include?(:audit)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all security audits'
                task audit: [:'ruby:audit'] do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :ruby do
                  desc 'Run Bundle Audit on the target application' \
                       "\n\tuse MIN_SEVERITY=(info low moderate high critical) to fetch only severity type selected and above (default=high)." \
                       "\n\tuse IGNORELIST=(comma delimited list of ids) removes the entry from the list."
                  task audit: %w(init_docker up_no_deps) do
                    opts = []
                    opts << '-T' if Dev::Common.new.running_codebuild?

                    # Retrieve results of the scan.
                    data = Dev::Docker::Compose.new(services: application, options: opts, capture: true).exec(*ruby.audit_command)
                    Dev::Ruby::Audit.new(data).to_report.check
                  end

                  # namespace :audit do
                  #   desc 'Run NPM Audit fix command'
                  #   task fix: %w(init_docker up_no_deps) do
                  #     raise 'not implemented'
                  #     # Dev::Docker::Compose.new(services: application).exec(*ruby.audit_fix_command)
                  #   end
                  # end
                end
              end
            end
          end
        end
      end
    end
  end
end
