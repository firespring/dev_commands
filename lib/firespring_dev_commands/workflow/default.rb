module Dev
  module Workflow
    class Default < Base
      Config = Struct.new(:project, :source_control, :code_review, :continuous_integration, :prefix) do
        def initialize
          self.project = nil
          self.source_control = nil
          self.code_review = nil
          self.continuous_integration = nil
          self.prefix = nil
        end
      end

      class << self
        # Instantiates a new top level config object if one hasn't already been created
        # Yields that config object to any given block
        # Returns the resulting config object
        def config
          @config ||= Config.new
          yield(@config) if block_given?
          @config
        end

        # Alias the config method to configure for a slightly clearer access syntax
        alias_method :configure, :config
      end

      attr_accessor :branch, :project, :source_control, :code_review, :continuous_integration

      def initialize(
        branch: nil,
        project: self.class.config.project,
        source_control: self.class.config.source_control,
        code_review: self.class.config.code_review,
        continuous_integration: self.class.config.continuous_integration
      )

        @prefix = prefix || 'feature'
        @branch = branch || ENV['BRANCH'].to_s.strip
        raise 'Must specify BRANCH as an environment variable' if @branch.strip.empty?
        raise "BRANCH should start with a '#{@prefix}/' prefix" unless @branch.start_with?("#{@prefix}/")

        #@release_branch = ENV['RELEASE_BRANCH'].to_s.strip
        #raise 'Must specify RELEASE_BRANCH as an environment variable' if @release_branch.strip.empty?
        #raise 'RELEASE_BRANCH should start with a \'release/\' prefix' unless @release_branch.start_with?('release/')

        #@name ||= branch.sub(/story\//, '')
        #@release_name ||= release_branch.sub(/release\//, '')
        #@number ||= name.downcase.match(/tp-([0-9]+).*/)&.[](1).to_i
        #@docker_tag = branch.gsub('/','_')



        @project = project || Dev::Workflow::Project::None.new
        raise "project must be a project" unless @project.is_a?(Dev::Workflow::Project::Base)

        @source_control = source_control || Dev::Workflow::SourceControl::Git.new
        raise "source control must be a source control" unless @source_control.is_a?(Dev::Workflow::SourceControl::Base)

        @code_review = code_review || Dev::Workflow::CodeReview::None.new
        raise "code review must be a code review" unless @code_review.is_a?(Dev::Workflow::CodeReview::Base)

        @continuous_integration = continuous_integration || Dev::Workflow::ContinuousIntegration::None.new
        raise "continuous integration must be a continuous integration" unless @continuous_integration.is_a?(Dev::Workflow::ContinuousIntegration::Base)

      end












      def start
        # TODO: Prerequisites
        #raise "Unable to authenticate with TargetProcess. Check your credentials" unless TargetProcess.new.authenticated?
        #raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?
        # 1.) Check WIP limits / prerequisites

        source_control.start
        # 2.) Use gitflow to start the story branch (specify alt base branch)

        project.start
        # If story was queried
        # 3.) Update the story to "In Progress"
        # 4.) Assign user and team to the story
        # 5.) Add auto-tasks to a story????
        # else
        # Log warning

        code_review.start

        continuous_integration.start
        # Nothing
      end

      # Audit? Test? 
      def review
        # TODO: Prerequisites
        #raise 'Unable to authenticate with TargetProcess. Check your credentials' unless TargetProcess.new.authenticated?
        #raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?
        # 1.) Check WIP limits / prerequisites
        # if story was queried
        # 2.) Require phase 1 and 2 SDL tasks be complete
        # 3.) Require all dev tasks be complete

        source_control.review
        # 4.) Merge base branch into the story branch to make sure it is up to date (try to honor alt base branch)

        project.review
        #if story was queried
        #  # 5.) Update the story to "In Testing"
        #else
        #  # Log warning

        code_review.review

        continuous_integration.review
      end

      def delete
        # TODO: Prerequisites
        #raise "Unable to authenticate with TargetProcess. Check your credentials" unless TargetProcess.new.authenticated?
        #raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?
        #raise 'The only valid values for FORCE_DELETE are blank and "true"' if ENV['FORCE_DELETE'] && ENV['FORCE_DELETE'] != 'true'

        source_control.delete
        # 1.) Delete the git branch (with confirmation)

        project.delete
        #if story was queried
        #  # 2.) Move the story to "Done"? Or do we delete it?

        code_review.delete

        continuous_integration.delete
        # 7.) Remove codepipeline if one exists

      end

      def finish
        # TODO: Prerequisites
        #raise 'Unable to authenticate with TargetProcess. Check your credentials' unless TargetProcess.new.authenticated?
        #raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?

        #%w[NO_SQUASH NO_CI NO_RELEASE_CLOSED NO_RELEASE_MATCH NO_BETA_REMOVE NO_PR].each do |x|
        #  raise "The only valid values for #{x} are blank or \"true\"" if ENV[x] && !ENV[x].casecmp?('true')
        #end
        #if story was queried
        #  # 1.) Require all tasks on the story to be complete
        # 2.) Require codepipeline builds to all have passed
        # 3.) Require the PR to have the correct signoffs
        # 4.) Require the release to exist and it's end date to be in the future
        # 5.) Require the release already defined on the story, if exists, to match the release we're finishing into

        source_control.finish
        # 6.) Merge the git branch in to the release (with confirmation)

        project.finish
        #if story was queried
        #  # 7.) Move the story to "QA Pending"
        #  # 8.) Assign the story to the release it was merged in to

        code_review.delete


        continuous_integration.finish
        # 13.) Remove story codepipeline if one exists
      end
    end
  end
end

=begin
# start


=end

=begin
# pr / review


    # 6.) Open a PR for this branch
      # if pr exists make sure it is open
      # else create a new PR
      # Create a new PR

    # 6.5) Notify slack if configured
    # 7.) Add labels to the PR if desired
    # 8.) Add user's dev team label to the PR
    # 9.) Create CI unless ENV['NO_CI'] == 'true'
=end

=begin
# delete



    # 3.) Close the PR
    # 4.) Remove a beta stack if one exists
    # 6.) Remove any docker images for this branch
=end

=begin
# finish




    # 9.) Close the PR
    # 10.) Remove a beta stack if one exists
    # 12.) Remove any docker images for this branch
=end
