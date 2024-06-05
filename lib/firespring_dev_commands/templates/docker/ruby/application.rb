require_relative '../../base_interface'

module Dev
  module Template
    module Docker
      # Module for rake tasks associated with ruby applications
      module Ruby
        # Class for default rake tasks associated with a ruby project
        class Application < Dev::Template::ApplicationInterface
          attr_reader :ruby, :start_container_dependencies_on_test, :test_isolation

          # Create the templated rake tasks for the ruby application
          #
          # @param application [String] The name of the application
          # @param container_path [String] The path to the application inside of the container
          # @param local_path [String] The path to the application on your local system
          # @param start_container_dependencies_on_test [Boolean] Whether or not to start up container dependencies when running tests
          # @param test_isolation [Boolean] Whether or not to start tests in an isolated project and clean up after tests are run
          # @param coverage [Dev::Coverage::Base] The coverage class which is an instance of Base to be used to evaluate coverage
          # @param lint_artifacts [Dev::Docker::Artifact] An array of lint artifacts to copy back from the container
          # @param test_artifacts [Dev::Docker::Artifact] An array of test artifacts to copy back from the container
          # @param exclude [Array<Symbol>] An array of default template tasks to exclude
          def initialize(
            application,
            container_path: nil,
            local_path: nil,
            start_container_dependencies_on_test: false,
            test_isolation: false,
            coverage: nil,
            lint_artifacts: nil,
            test_artifacts: nil,
            exclude: []
          )
            @ruby = Dev::Ruby.new(container_path:, local_path:, coverage:)
            @start_container_dependencies_on_test = start_container_dependencies_on_test
            @test_isolation = test_isolation
            @lint_artifacts = lint_artifacts
            @test_artifacts = test_artifacts
            raise 'lint artifact must be instance of Dev::Docker::Artifact' if lint_artifacts&.any? { |it| !it.is_a?(Dev::Docker::Artifact) }
            raise 'test artifact must be instance of Dev::Docker::Artifact' if test_artifacts&.any? { |it| !it.is_a?(Dev::Docker::Artifact) }

            super(application, exclude:)
          end

          # rubocop:disable Metrics/MethodLength
          # Create the rake task which runs linting for the application name
          def create_lint_task!
            application = @name
            ruby = @ruby
            exclude = @exclude
            lint_artifacts = @lint_artifacts
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
                  desc "Run the ruby linting software against the #{application}'s codebase" \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task lint: %w(init_docker up_no_deps) do
                    LOG.debug("Check for ruby linting errors in the #{application} codebase")

                    # Run the lint command
                    options = []
                    options << '-T' if Dev::Common.new.running_codebuild?
                    Dev::Docker::Compose.new(services: application, options:).exec(*ruby.lint_command)
                  ensure
                    # Copy any defined artifacts back
                    container = Dev::Docker::Compose.new.container_by_name(application)
                    lint_artifacts&.each do |artifact|
                      Dev::Docker.new.copy_from_container(container, artifact.container_path, artifact.local_path)
                    end
                  end

                  namespace :lint do
                    desc "Run the ruby linting software against the #{application}'s codebase and apply all available fixes"
                    task fix: %w(init_docker up_no_deps) do
                      LOG.debug("Check and fix all ruby linting errors in the #{application} codebase")

                      # Run the lint fix command
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

          # rubocop:disable Metrics/MethodLength
          # Create the rake task which runs all tests for the application name
          def create_test_task!
            application = @name
            ruby = @ruby
            exclude = @exclude
            test_isolation = @test_isolation
            up_cmd = @start_container_dependencies_on_test ? :up : :up_no_deps
            test_artifacts = @test_artifacts
            return if exclude.include?(:test)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all tests'
                task test: [:'ruby:test'] do
                  # This is just a placeholder to execute the dependencies
                end

                task test_init_docker: %w(init_docker) do
                  Dev::Docker::Compose.configure do |c|
                    c.project_name = SecureRandom.hex if test_isolation
                  end
                end

                namespace :ruby do
                  desc "Run all ruby tests against the #{application}'s codebase" \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task test: %W(test_init_docker #{up_cmd}) do
                    begin
                      LOG.debug("Running all ruby tests in the #{application} codebase")

                      options = []
                      options << '-T' if Dev::Common.new.running_codebuild?
                      Dev::Docker::Compose.new(services: application, options:).exec(*ruby.test_command)
                      ruby.check_test_coverage(application:)
                    ensure
                      # Copy any defined artifacts back
                      container = Dev::Docker::Compose.new.container_by_name(application)
                      test_artifacts&.each do |artifact|
                        Dev::Docker.new.copy_from_container(container, artifact.container_path, artifact.local_path)
                      end
                    end
                  ensure
                    # Clean up resources if we are on an isolated project name
                    if test_isolation
                      Dev::Docker::Compose.new.down
                      Dev::Docker.new.prune_project_volumes(project_name: Dev::Docker::Compose.config.project_name)
                    end
                  end
                end
              end
            end
          end
          # rubocop:enable Metrics/MethodLength

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
                       "\n\tuse IGNORELIST=(comma delimited list of ids) removes the entry from the list." \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
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

          # Create the rake task for the ruby eol method
          def create_eol_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            exclude = @exclude
            ruby = @ruby

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              return if exclude.include?(:eol)

              task eol: [:'eol:ruby'] do
                # This is just a placeholder to execute the dependencies
              end

              namespace :eol do
                desc 'Compares the current date to the EOL date for supported packages in the ruby package file'
                task ruby: %w(init) do
                  eol = Dev::EndOfLife::Ruby.new(ruby)
                  ruby_products = eol.default_products

                  puts
                  puts "Ruby product versions (in #{eol.lockfile})".light_yellow
                  Dev::EndOfLife.new(product_versions: ruby_products).status
                end
              end
            end
          end
        end
      end
    end
  end
end
