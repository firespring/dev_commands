require 'aws-sdk-codepipeline'

module Dev
  class Aws
    # Class for performing codepipeline functions
    class CodePipeline
      attr_reader :client

      def initialize
        @client = nil
      end

      # Create/set a new client if none is present
      # Return the client
      def client
        @client ||= ::Aws::CodePipeline::Client.new
      end

      # Get a list of all pipelines in the aws account
      # Optionally filter by the regex_match
      def pipelines(regex_match = nil)
        raise 'regex_match must be a regexp' if regex_match && !regex_match.is_a?(Regexp)

        pipelines = [].tap do |ary|
          Dev::Aws::each_page(client, :list_pipelines) do |response|
            ary.concat(response.pipelines)
          end
        end

        pipelines.select! { |it| it.name.match(regex_match) } if regex_match
        pipelines
      end

      # Find all pipelines matching the regex_match and find the status for each of them
      def status(name)
        pipeline = client.get_pipeline_state(name:)
        print_pipeline_information(pipeline)
      rescue ::Aws::CodePipeline::Errors::PipelineNotFoundException
        LOG.error "No pipeline found with name #{name}".light_yellow
      end

      # Iterate over each pipeline stage and call the method to print stage information for each
      private def print_pipeline_information(pipeline)
        puts pipeline.pipeline_name.light_white
        pipeline.stage_states.each do |stage_state|
          print_stage_state_information(stage_state)
        end
      end

      # Print Stage information
      # Iterate over each stage action state and call the method to print information for each
      # Ignore the source steps because they are usually boring
      private def print_stage_state_information(stage_state)
        # Source step is not exciting - don't print it
        return if stage_state.stage_name.to_s.strip == 'Source'

        puts "  Stage: #{stage_state.stage_name.light_blue}"
        stage_state.action_states.each do |action_state|
          print_action_state_information(action_state)
        end
      end

      # Print Action State information
      # Call the method to print execution information
      private def print_action_state_information(action_state)
        puts "    Action: #{action_state.action_name.light_blue}"
        print_latest_execution_information(action_state.latest_execution)
      end

      # Print the latest execution information
      private def print_latest_execution_information(latest_execution)
        status = latest_execution&.status
        last_status_change = latest_execution&.last_status_change
        error_details = latest_execution&.error_details

        puts "      Date:       #{last_status_change&.to_s&.light_white}"
        puts "      State:      #{colorize_status(status)}"
        puts "      Details:    #{error_details&.message&.light_yellow}" if error_details
      end

      # Colorize the status output based on the success or failure of the pipeline
      private def colorize_status(status)
        return status.light_green if status == 'Succeeded'
        return status.light_yellow if %w(Abandoned InProgress).include?(status)

        status&.light_red
      end
    end
  end
end
