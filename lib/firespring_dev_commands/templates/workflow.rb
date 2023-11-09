require_relative 'base_interface'

module Dev
  module Template
    class Workflow < Dev::Template::BaseInterface
      attr_reader :workflow

      # Create workflow templated commands
      def initialize(workflow: nil, exclude: [])
        @workflow = workflow || Dev::Workflow::Default.new

        raise "workflow must be a workflow" unless @workflow.is_a?(Dev::Workflow::Base)

        super(exclude:)
      end

      def create_start_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude
        workflow = @workflow

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace workflow.prefix do
            return if exclude.include?(:start)

            # TODO Add what variables you can pass in to configure your workflow
            desc 'Perform the "start" workflow' \
                 "\n\tmore TODO"
            task start: %w(init) do
              workflow.start
            end
          end
        end
      end

      def create_review_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude
        workflow = @workflow

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace workflow.prefix do
            return if exclude.include?(:review)

            desc 'Perform the "review" workflow' \
                 "\n\tmore TODO"
            task review: %w(init) do
              workflow.review
            end
          end
        end
      end


      def create_delete_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude
        workflow = @workflow

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace workflow.prefix do
            return if exclude.include?(:delete)

            desc 'Perform the "delete" workflow' \
                 "\n\tmore TODO"
            task delete: %w(init) do
              workflow.delete
            end
          end
        end
      end

      def create_finish_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude
        workflow = @workflow

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace workflow.prefix do
            return if exclude.include?(:finish)

            desc 'Perform the "finish" workflow' \
                 "\n\tmore TODO"
            task finish: %w(init) do
              workflow.finish
            end
          end
        end
      end
    end
  end
end
