require_relative '../../base_interface'

module Dev
  module Template
    module Docker
      # Module for rake tasks associated with node applications
      module Node
        # Class for default rake tasks associated with a node project
        class Application < Dev::Template::ApplicationInterface
          attr_reader :node, :start_container_dependencies_on_test, :test_isolation

          # Create the templated rake tasks for the node application
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
            @node = Dev::Node.new(container_path:, local_path:, coverage:)
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
            node = @node
            exclude = @exclude
            lint_artifacts = @lint_artifacts
            return if exclude.include?(:lint)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all linting software'
                task lint: %w(node:lint) do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :lint do
                  desc 'Run all linting software and apply all available fixes'
                  task fix: %w(node:lint:fix) do
                    # This is just a placeholder to execute the dependencies
                  end
                end

                namespace :node do
                  desc "Run the node linting software against the #{application}'s codebase" \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task lint: %w(init_docker up_no_deps) do
                    LOG.debug("Check for node linting errors in the #{application} codebase")

                    # Run the lint command
                    options = []
                    options << '-T' if Dev::Common.new.running_codebuild?
                    Dev::Docker::Compose.new(services: application, options:).exec(*node.lint_command)
                  ensure
                    # Copy any defined artifacts back
                    container = Dev::Docker::Compose.new.container_by_name(application)
                    lint_artifacts&.each do |artifact|
                      Dev::Docker.new.copy_from_container(container, artifact.container_path, artifact.local_path)
                    end
                  end

                  namespace :lint do
                    desc "Run the linting software against the #{application}'s codebase and apply all available fixes"
                    task fix: %w(init_docker up_no_deps) do
                      LOG.debug("Check and fix all node linting errors in the #{application} codebase")

                      options = []
                      options << '-T' if Dev::Common.new.running_codebuild?
                      Dev::Docker::Compose.new(services: application, options:).exec(*node.lint_fix_command)
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
            node = @node
            exclude = @exclude
            test_isolation = @test_isolation
            up_cmd = @start_container_dependencies_on_test ? :up : :up_no_deps
            test_artifacts = @test_artifacts
            return if exclude.include?(:test)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all tests'
                task test: %w(node:test) do
                  # This is just a placeholder to execute the dependencies
                end

                task test_init_docker: %w(init_docker) do
                  Dev::Docker::Compose.configure do |c|
                    c.project_name = SecureRandom.hex if test_isolation
                  end
                end

                namespace :node do
                  desc "Run all node tests against the #{application}'s codebase" \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task test: %W(test_init_docker #{up_cmd}) do
                    begin
                      LOG.debug("Running all node tests in the #{application} codebase")

                      # Run the test command
                      options = []
                      options << '-T' if Dev::Common.new.running_codebuild?
                      Dev::Docker::Compose.new(services: application, options:).exec(*node.test_command)
                      node.check_test_coverage(application:)
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
            node = @node
            exclude = @exclude
            return if exclude.include?(:install)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                namespace :node do
                  desc 'Install all npm packages'
                  task install: %w(init_docker up_no_deps) do
                    Dev::Docker::Compose.new(services: application).exec(*node.install_command)
                  end
                end
              end
            end
          end

          # Create the rake tasks which runs the security audits of application packages
          def create_audit_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            application = @name
            node = @node
            exclude = @exclude
            return if exclude.include?(:audit)

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              namespace application do
                desc 'Run all security audits'
                task audit: %w(node:audit) do
                  # This is just a placeholder to execute the dependencies
                end

                namespace :node do
                  desc 'Run NPM Audit on the target application' \
                       "\n\tuse MIN_SEVERITY=(info low moderate high critical) to fetch only severity type selected and above (default=high)." \
                       "\n\tuse IGNORELIST=(comma delimited list of ids) removes the entry from the list." \
                       "\n\t(optional) use OPTS=... to pass additional options to the command"
                  task audit: %w(init_docker up_no_deps) do
                    opts = []
                    opts << '-T' if Dev::Common.new.running_codebuild?

                    # Run the audit command and retrieve the results
                    data = Dev::Docker::Compose.new(services: application, options: opts, capture: true).exec(*node.audit_command)
                    Dev::Node::Audit.new(data).to_report.check
                  end

                  namespace :audit do
                    desc 'Run NPM Audit fix command'
                    task fix: %w(init_docker up_no_deps) do
                      Dev::Docker::Compose.new(services: application).exec(*node.audit_fix_command)
                    end
                  end
                end
              end
            end
          end

          # Create the rake task for the node eol method
          def create_eol_task!
            # Have to set a local variable to be accessible inside of the instance_eval block
            exclude = @exclude
            node = @node

            DEV_COMMANDS_TOP_LEVEL.instance_eval do
              return if exclude.include?(:eol)

              task eol: [:'eol:node'] do
                # This is just a placeholder to execute the dependencies
              end

              namespace :eol do
                desc 'Compares the current date to the EOL date for supported packages in the node package file'
                task node: %w(init) do
                  eol = Dev::EndOfLife::Node.new(node)
                  node_products = eol.default_products

                  puts
                  puts "Node product versions (in #{eol.lockfile})".light_yellow
                  Dev::EndOfLife.new(product_versions: node_products).status
                end
              end
            end
          end
        end
      end
    end
  end
end
