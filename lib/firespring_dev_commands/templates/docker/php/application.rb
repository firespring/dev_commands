require_relative '../../base_interface'
require 'securerandom'

module Dev
  module Template
    module Docker
      # Module for rake tasks associated with php applications
      module Php
        # Class for default rake tasks associated with a php project
        class Application < Dev::Template::ApplicationInterface
          attr_reader :php, :test_isolation, :test_deps

          # Create the templated rake tasks for the php application
          #
          # @param application [String] The name of the application
          # @param container_path [String] The path to the application inside of the container
          # @param local_path [String] The path to the application on your local system
          # @param test_isolation [Boolean] Whether or not to start tests in an isolated project and clean up after tests are run
          # @param test_deps [Boolean] Whether or not to start container dependencies when running tests
          # @param coverage [Dev::Coverage::Base] The coverage class which is an instance of Base to be used to evaluate coverage
          # TODO: Auto copy all artifacts back?
          def initialize(
            application,
            container_path: nil,
            local_path: nil,
            test_isolation: false,
            test_deps: false,
            coverage: nil,
            exclude: []
          )
            @php = Dev::Php.new(container_path:, local_path:, coverage:)
            @test_isolation = test_isolation
            @test_deps = test_deps

            super(application, exclude:)
          end

          # Create the rake task which downloads the vendor directory to your local system for the given application name
          def create_vendor_download_task!
            application = @name
            php = @php
            exclude = @exclude
            return if exclude.include?(:'vendor:download')

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                namespace :php do
                  namespace :vendor do
                    desc "Copy #{application} vendor files from the container to your local system"
                    task download: %w(init_docker up_no_deps) do
                      container = Dev::Docker::Compose.new.container_by_name(application)
                      Dev::Docker.new.copy_from_container(container, "#{php.container_path}/vendor/", "#{php.local_path}/vendor/", required: true)
                    end
                  end
                end
              end
            end
          end

          # Create the rake task which uploads the vendor directory from your local system for the given application name
          def create_vendor_upload_task!
            application = @name
            php = @php
            exclude = @exclude
            return if exclude.include?(:'vendor:upload')

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                namespace :php do
                  namespace :vendor do
                    desc "Copy #{application} vendor files from your local system to the container"
                    task upload: %w(init_docker up_no_deps) do
                      container = Dev::Docker::Compose.new.container_by_name(application)
                      Dev::Docker.new.copy_to_container(container, "#{php.local_path}/vendor/", "#{php.container_path}/vendor/")
                    end
                  end
                end
              end
            end
          end

          # Create the rake task which runs linting for the application name
          def create_lint_task!
            application = @name
            php = @php
            run_new_container = @run_new_container
            exclude = @exclude
            return if exclude.include?(:lint)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all linting software'
                task lint: %w(php:lint) do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :php do
                  desc "Run the php linting software against the #{application}'s codebase" \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task lint: %w(init_docker up_no_deps) do
                    LOG.debug("Check for php linting errors in the #{application} codebase")

                    options = []
                    options << '-T' if Dev::Common.new.running_codebuild?
                    Dev::Docker::Compose.new(services: application, options:).exec(*php.lint_command)
                  end

                  namespace :lint do
                    desc "Run the php linting software against the #{application}'s codebase and apply all available fixes"
                    task fix: %w(init_docker up_no_deps) do
                      LOG.debug("Check and fix all php linting errors in the #{application} codebase")

                      options = []
                      options << '-T' if Dev::Common.new.running_codebuild?
                      Dev::Docker::Compose.new(services: application, options:).exec(*php.lint_fix_command)
                    end
                  end
                end
              end
            end
          end

          # Create the rake task which runs all tests for the application name
          def create_test_task!
            application = @name
            php = @php
            test_isolation = @test_isolation
            up_cmd = @test_deps ? :up : :up_no_deps
            exclude = @exclude
            return if exclude.include?(:test)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all tests'
                task test: %w(php:test) do
                  # This is just a placeholder to execute the dependencies
                end

                task test_init_docker: %w(init_docker) do
                  Dev::Docker::Compose::configure do |c|
                    c.project_name = SecureRandom.hex if test_isolation
                  end
                end

                namespace :php do
                  desc "Run all php tests against the #{application}'s codebase" \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task test: %W(test_init_docker #{up_cmd}) do
                    LOG.debug("Running all php tests in the #{application} codebase")

                    options = []
                    options << '-T' if Dev::Common.new.running_codebuild?
                    Dev::Docker::Compose.new(services: application, options:).exec(*php.test_command)
                    php.check_test_coverage(application:)

                    # Clean up resources if we are on an isolated project name
                    if test_isolation
                      Dev::Docker::Compose.new.down
                      #Can we remove volumes in down?
                      Dev::Docker.new.prune_project_volumes(project_name: Dev::Docker::Compose.config.project_name)
                    end
                  end
                end
              end
            end
          end

          # Create the rake tasks which runs the install command for the application packages
          def create_install_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            application = @name
            php = @php
            exclude = @exclude
            return if exclude.include?(:install)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                namespace :php do
                  desc 'Install all composer packages'
                  task install: %w(init_docker up_no_deps) do
                    Dev::Docker::Compose.new(services: application).exec(*php.install_command)
                  end
                end
              end
            end
          end

          # Create the rake tasks which runs the security audits for the application packages
          def create_audit_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            application = @name
            php = @php
            run_new_container = @run_new_container
            exclude = @exclude
            return if exclude.include?(:audit)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all security audits'
                task audit: %w(php:audit) do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :php do
                  desc 'Run Composer Audit on the target application' \
                       "\n\tuse MIN_SEVERITY=(info low moderate high critical) to fetch only severity type selected and above (default=high)." \
                       "\n\tuse IGNORELIST=(comma delimited list of cwe numbers) removes the entry from the list." \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task audit: %w(init_docker up_no_deps) do
                    # TODO: Conditionally run up unless running new container???
                    # TODO: Change exec to run command, auto-remove?
                    opts = []
                    opts << '-T' if Dev::Common.new.running_codebuild?

                    # Retrieve results of the scan.
                    data = Dev::Docker::Compose.new(services: application, options: opts, capture: true).exec(*php.audit_command)
                    Dev::Php::Audit.new(data).to_report.check
                  end

                  # namespace :audit do
                  #   desc 'Fix the composer vulnerabilities that were found'
                  #   task fix: %w(init_docker up_no_deps) do
                  #     raise 'not implemented'
                  #     # Dev::Docker::Compose.new(services: application).exec(*php.audit_fix_command)
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
