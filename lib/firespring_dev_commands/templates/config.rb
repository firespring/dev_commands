require_relative 'base_interface'

module Dev
  module Template
    # Contains all default rake tasks for a docker application
    class Application
      # Contains rake tasks for displaying and setting application variables in parameter store
      class Config < Dev::Template::ApplicationInterface
        attr_reader :path

        # Allow for custom config path for the application
        def initialize(name, path, exclude: [])
          @path = path
          super(name, exclude:)
        end

        # Create the list rake task
        def create_list_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          application = @name
          path = @path
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              namespace :config do
                return if exclude.include?(:list)

                desc "List all #{application} configs"
                task list: %w(init) do
                  puts
                  Dev::Aws::Parameter.new.list(path).each do |it|
                    puts "  #{it.name} => #{it.value} (#{it.type})"
                  end
                  puts
                end
              end
            end
          end
        end

        # rubocop:disable Metrics/MethodLength
        # Create the set task
        def create_set_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          application = @name
          path = @path
          exclude = @exclude

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace application do
              namespace :config do
                return if exclude.include?(:set)

                desc 'Updates the parameter with the given name to the new value' \
                     "\n\tspecify NAME as the name of the parameter to be set (it will be prefixed with the base path for this app)" \
                     "\n\tspecify VALUE is required and is the value you wish the paramete to be set to" \
                     "\n\toptionally specify ENCRYPT=true to change a String type to a SecureString type"
                task set: %w(ensure_aws_credentials) do
                  raise 'NAME is required' if ENV['NAME'].to_s.strip.blank?
                  raise 'NAME is not found in this apps parameters' if Dev::Aws::Parameter.new.list(path).none? { |it| it.name == ENV['NAME'] }
                  raise 'VALUE is required' if ENV['VALUE'].to_s.strip.blank?

                  param_path = ENV.fetch('NAME', nil)
                  new_value = ENV.fetch('VALUE', nil)
                  old_value = Dev::Aws::Parameter.new.get(param_path)

                  params = {type: 'String'}
                  if ENV['ENCRYPT'].to_s.strip == 'true' || old_value.type == 'SecureString'
                    params[:type] = 'SecureString'
                    params[:key_id] = Dev::Aws::Parameter.new.get_value("#{path}/kms/id")
                  end

                  message = 'This will change '.light_green +
                            param_path.light_yellow +
                            ' from "'.light_green +
                            old_value.value.light_yellow +
                            '" ('.light_green +
                            old_value.type.light_yellow +
                            ') to "'.light_green +
                            new_value.light_yellow +
                            '" ('.light_green +
                            params[:type].light_yellow +
                            '). Continue'.light_green
                  Dev::Common.new.with_confirmation(message, color_message: false) do
                    Dev::Aws::Parameter.new.put(param_path, new_value, **params)
                  end
                end
              end
            end
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
