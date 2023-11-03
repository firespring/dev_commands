module Dev
  module Workflow
    class Default < Base
      attr_accessor :project, :source_control, :continuous_integration

      def initialize(project: nil, source_control: nil, review: nil, continuous_integration: nil)
        @project = project || Dev::Workflow::Project::None.new
        raise "project must be a project" unless @project.is_a?(Dev::Workflow::Project::Base)

        @source_control = source_control || Dev::Workflow::SourceControl::None.new
        raise "source control must be a source control" unless @source_control.is_a?(Dev::Workflow::SourceControl::Base)

        @continuous_integration = continuous_integration || Dev::Workflow::ContinuousIntegration::None.new
        raise "continuous integration must be a continuous integration" unless @continuous_integration.is_a?(Dev::Workflow::ContinuousIntegration::Base)

      end

      def start
        project.start
        source_control.start
        continuous_integration.start
      end

      def review
        project.review
        source_control.review
        continuous_integration.review
      end

      def finish
        project.finish
        source_control.finish
        continuous_integration.finish
      end

      def delete
        project.delete
        source_control.delete
        continuous_integration.delete
      end
    end
  end
end
