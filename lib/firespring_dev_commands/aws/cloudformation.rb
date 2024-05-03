require 'securerandom'
require 'aws-sdk-s3'
require 'aws-sdk-cloudformation'

module Dev
  class Aws
    # Class for performing cloudformation functions
    class Cloudformation
      # Not Started status
      NOT_STARTED = :not_started

      # Started status
      STARTED = :started

      # No Changes status
      NO_CHANGES = :no_changes

      # Failed status
      FAILED = :failed

      # Finished status
      FINISHED = :finished

      attr_accessor :client, :name, :template_filename, :parameters, :capabilities, :failure_behavior, :preserve_parameters_on_update, :state

      def initialize(name, template_filename, parameters: Dev::Aws::Cloudformation::Parameters.new, capabilities: [], failure_behavior: 'ROLLBACK',
                     preserve_parameters_on_update: false)
        raise 'parameters must be an intsance of parameters' unless parameters.is_a?(Dev::Aws::Cloudformation::Parameters)

        @client = nil
        @name = name
        @template_filename = template_filename
        @parameters = parameters
        @capabilities = capabilities
        @failure_behavior = failure_behavior
        @preserve_parameters_on_update = preserve_parameters_on_update
        @state = NOT_STARTED
      end

      # Create/set a new client if none is present
      # Return the client
      def client
        @client ||= ::Aws::CloudFormation::Client.new
      end

      # Create the cloudformation stack
      def create(should_wait: true)
        # Call upload function to get the s3 url
        template_url = upload(template_filename)

        # Create the cloudformation stack
        client.create_stack(
          stack_name: name,
          template_url:,
          parameters: parameters.default,
          capabilities:,
          on_failure: failure_behavior
        )
        @state = STARTED
        LOG.info "#{name} stack create started at #{Time.now.to_s.light_yellow}"

        # return if we aren't waiting here
        return unless should_wait

        # Wait if we are supposed to wait
        create_wait
        @state = FINISHED
        LOG.info "#{name} stack create finished at #{Time.now.to_s.light_yellow}"
      rescue => e
        LOG.error "Error creating stack: #{e.message}"
        @state = FAILED
      end

      # Get the cloudformation stack
      def exist?
        !client.describe_stacks(stack_name: name).stacks.empty?
      rescue ::Aws::CloudFormation::Errors::ValidationError
        false
      end

      # Update the cloudformation stack
      def update(should_wait: true)
        # Call upload function to get the s3 url
        template_url = upload(template_filename)

        update_parameters = if preserve_parameters_on_update
                              parameters.preserve
                            else
                              parameters.default
                            end
        # Update the cloudformation stack
        client.update_stack(
          stack_name: name,
          template_url:,
          parameters: update_parameters,
          capabilities:
        )
        @state = STARTED
        LOG.info "#{name} stack update started at #{Time.now.to_s.light_yellow}"

        # return if we aren't waiting here
        return unless should_wait

        # Wait if we are supposed to wait
        update_wait
        @state = FINISHED
        LOG.info "#{name} stack update finished at #{Time.now.to_s.light_yellow}"
      rescue => e
        if /no updates/i.match?(e.message)
          LOG.info "No updates to needed on #{name}".light_yellow
          @state = NO_CHANGES
        else

          LOG.error "Error updating stack: #{e.message}"
          @state = FAILED
        end
      end

      # Delete the cloudformation stack
      def delete(should_wait: true)
        # Delete the cloudformation stack
        client.delete_stack(stack_name: name)
        @state = STARTED
        LOG.info "#{name} stack delete started at #{Time.now.to_s.light_yellow}"

        # Return if we aren't waiting here
        return unless should_wait

        # Wait if we are supposed to wait
        delete_wait
        @state = FINISHED
        LOG.info "#{name} stack delete finished at #{Time.now.to_s.light_yellow}"
      rescue => e
        LOG.error "Error deleting stack: #{e.message}"
        @state = FAILED
      end

      # Wait for create complete
      def create_wait
        wait(name, :create_complete)
      end

      # Wait for update complete
      def update_wait
        wait(name, :update_complete)
      end

      # Wait for delete complete
      def delete_wait
        wait(name, :delete_complete)
      end

      # Wait for the stack name to complete the specified type of action
      # Defaults to exists
      def wait(stack_name, type = 'exists', max_attempts: 360, delay: 5)
        # Don't wait if there's nothing to wait for
        return if no_changes? || finished?

        client.wait_until(
          :"stack_#{type}",
          {stack_name:},
          {max_attempts:, delay:}
        )
      rescue ::Aws::Waiters::Errors::WaiterFailed => e
        raise "Action failed to complete: #{e.message}"
      end

      # State matches the not started state
      def not_started?
        state == NOT_STARTED
      end

      # State matches the started state
      def started?
        state == STARTED
      end

      # State matches the no_changes state
      def no_changes?
        state == NO_CHANGES
      end

      # State matches the failed state
      def failed?
        state == FAILED
      end

      # State matches the finished state
      def finished?
        state == FINISHED
      end

      # Uploads the filename to the cloudformation templates bucket and returns the url of the file
      private def upload(filename)
        s3 = Dev::Aws::S3.new
        template_bucket = s3.cf_bucket.name
        key = "#{File.basename(filename)}/#{SecureRandom.uuid}"
        s3.put(bucket: template_bucket, key:, filename:)
      end
    end
  end
end
