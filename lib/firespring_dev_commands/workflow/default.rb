module Dev
  module Workflow
    class Default < Base
      attr_accessor :project_management, :sc_management, :review_management, :cicd_management

      def initialize(project_management: nil, sc_management: nil, review_management: nil, cicd_management: nil)
        @project_management = project_management || Dev::Workflow::Project::None.new
        @sc_management = sc_management || Dev::Workflow::SourceControl::None.new
        @review_management = review_management || Dev::Workflow::Review::None.new
        @cicd_management = cicd_management || Dev::Workflow::ContinuousIntegration::None.new
      end

      def start
        project_management.start
        sc_management.start
        review_management.start
        cicd_management.start
      end

      def review
        project_management.review
        sc_management.review
        review_management.review
        cicd_management.review
      end

      def finish
        project_management.finish
        sc_management.finish
        review_management.finish
        cicd_management.finish
      end

      def delete
        project_management.delete
        sc_management.delete
        review_management.delete
        cicd_management.delete
      end
    end
  end
end
