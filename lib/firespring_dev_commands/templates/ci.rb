require_relative './base_interface'

module Dev
  module Template
    class Aws
      # Class contains rake templates for managing your ci/cd resources
      class Ci < Dev::Template::BaseInterface
        # Base interface template customized for codepipelines which require a pipeline pattern which will match the pipeline name
        def initialize(cloudformation, exclude: [])
          @cloudformations = Array(cloudformation).sort_by(&:name)
          raise 'must specify an arry of cloudformation objects' unless @cloudformations.all?(Dev::Aws::Cloudformation)

          super(exclude: exclude)
        end

        # Create the rake task for creating the codepipeline
        def create_create_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          exclude = @exclude
          cloudformations = @cloudformations
          return if exclude.include?(:status)

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace :ci do
              desc 'Create the ci cloudformation stack in aws'
              task create: %w(init ensure_aws_credentials) do
                LOG.info
                next if cloudformations.empty?

                # Start create on all stacks without waiting so they are created in parallel
                cloudformations.each do |cloudformation|
                  cloudformation.create(should_wait: false)
                end
                LOG.info 'Waiting for all stacks to finish create'

                # Wait until all stacks have finished creating
                cloudformations.each(&:create_wait)
                LOG.info "Stack create finished at #{Time.now.to_s.light_yellow}"
                LOG.info

                raise 'Some stacks failed to create' if cloudformations.any?(&:failed?)
              end
            end
          end
        end

        # Create the rake task for updating the codepipeline
        def create_update_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          exclude = @exclude
          cloudformations = @cloudformations
          return if exclude.include?(:status)

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace :ci do
              desc 'Update the ci cloudformation stack in aws'
              task update: %w(init ensure_aws_credentials) do
                LOG.info
                next if cloudformations.empty?

                # Start update on all stacks without waiting so they are updated in parallel
                cloudformations.each do |cloudformation|
                  cloudformation.update(should_wait: false)
                end
                LOG.info 'Waiting for all stacks to finish update'

                # Wait until all stacks have finished creating
                cloudformations.each(&:update_wait)
                LOG.info "Stack update finished at #{Time.now.to_s.light_yellow}"
                LOG.info

                raise 'Some stacks failed to update' if cloudformations.any?(&:failed?)
              end
            end
          end
        end

        # Create the rake task for deleting the codepipeline
        def create_delete_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          exclude = @exclude
          cloudformations = @cloudformations
          return if exclude.include?(:status)

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace :ci do
              desc 'Delete the ci cloudformation stack in aws'
              task delete: %w(init ensure_aws_credentials) do
                LOG.info
                next if cloudformations.empty?

                # Start delete on all stacks without waiting so they are deleted in parallel
                cloudformations.each do |cloudformation|
                  cloudformation.delete(should_wait: false)
                end
                LOG.info 'Waiting for all stacks to finish delete'

                # Wait until all stacks have finished creating
                cloudformations.each(&:delete_wait)
                LOG.info "Stack delete finished at #{Time.now.to_s.light_yellow}"
                LOG.info

                raise 'Some stacks failed to update' if cloudformations.any?(&:failed?)
              end
            end
          end
        end

        # Create the rake task for the aws codepipeline status method
        def create_status_task!
          # Have to set a local variable to be accessible inside of the instance_eval block
          exclude = @exclude
          cloudformations = @cloudformations
          return if exclude.include?(:status)

          DEV_COMMANDS_TOP_LEVEL.instance_eval do
            namespace :ci do
              desc 'Show the current status of the pipelines associated with your branch'
              task status: %w(init ensure_aws_credentials) do
                LOG.info
                next if cloudformations.empty?

                pattern = /#{cloudformations.map(&:name).join('|')}/
                pipelines = Dev::Aws::CodePipeline.new.pipelines(pattern).sort_by(&:name)
                LOG.info "No pipelines found matching #{pattern.source.gsub('|', ' OR ')}" if pipelines.empty?
                pipelines.each do |pipeline|
                  Dev::Aws::CodePipeline.new.status(pipeline.name)
                  LOG.info
                end
                LOG.info
              end
            end
          end
        end
      end
    end
  end
end
