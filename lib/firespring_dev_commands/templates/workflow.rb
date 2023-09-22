# TODO: Need custom pre/post hooks
# TODO: Need bypass options?

require_relative 'base_interface'

module Dev
  module Template
    class Workflow < Dev::Template::BaseInterface
      attr_reader :prefix, :project_management, :sc_management, :neview_management, :cicd_management

      # Base interface template customized for codepipelines which require a pipeline pattern which will match the pipeline name
      def initialize(prefix: 'feature', project_management: nil, sc_management: nil, review_management: nil, cicd_management: nil, exclude: [])
        @prefix = prefix || 'feature'
        @project_management = project_management || Dev::Workflow::Project::None.new
        @sc_management = sc_management || Dev::Workflow::SourceControl::None.new
        @review_management = review_management || Dev::Workflow::Review::None.new
        @cicd_management = cicd_management || Dev::Workflow::ContinuousIntegration::None.new

        super(exclude:)
      end

      def create_start_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude
        prefix = @prefix
        project_management = @project_management
        sc_management = @sc_management

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace prefix do
            return if exclude.include?(:start)

            desc 'TODO' \
                 "\n\tmore TODO"
            task start: %w(init) do
              raise "Unable to authenticate with #{project_management.name}" unless project_management&.credentials&.active?
              raise "Unable to authenticate with #{sc_management.name}" unless sc_management&.credentials&.active?

              project_management.start.prerequisites
              sc_management.start.create_branches

            end
          end
        end









=begin
# start
    raise "Unable to authenticate with TargetProcess. Check your credentials" unless TargetProcess.new.authenticated?
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?

    # 1.) Check WIP limits / prerequisites
    # 2.) Use gitflow to start the story branch (specify alt base branch)

    # If story was queried
      # 3.) Update the story to "In Progress"
      # 4.) Assign user and team to the story
      # 5.) Add auto-tasks to a story????
    # else
      # Log warning
=end











=begin
# pr / review
    raise 'Unable to authenticate with TargetProcess. Check your credentials' unless TargetProcess.new.authenticated?
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?

    # 1.) Check WIP limits / prerequisites

    # if story was queried
        # 2.) Require phase 1 and 2 SDL tasks be complete
        # 3.) Require all dev tasks be complete

    # 4.) Merge base branch into the story branch to make sure it is up to date (try to honor alt base branch)

    if story was queried
      # 5.) Update the story to "In Testing"
    else
      # Log warning

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
    raise "Unable to authenticate with TargetProcess. Check your credentials" unless TargetProcess.new.authenticated?
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?
    raise 'The only valid values for FORCE_DELETE are blank and "true"' if ENV['FORCE_DELETE'] && ENV['FORCE_DELETE'] != 'true'

    # 1.) Delete the git branch (with confirmation)

    if story was queried
      # 2.) Move the story to "Done"? Or do we delete it? 

    # 3.) Close the PR
    # 4.) Remove a beta stack if one exists
    # 6.) Remove any docker images for this branch
    # 7.) Remove codepipeline if one exists
=end

=begin
# finish
    raise 'Unable to authenticate with TargetProcess. Check your credentials' unless TargetProcess.new.authenticated?
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?

    %w[NO_SQUASH NO_CI NO_RELEASE_CLOSED NO_RELEASE_MATCH NO_BETA_REMOVE NO_PR].each do |x|
      raise "The only valid values for #{x} are blank or \"true\"" if ENV[x] && !ENV[x].casecmp?('true')
    end

    if story was queried
      # 1.) Require all tasks on the story to be complete

    # 2.) Require codepipeline builds to all have passed
    # 3.) Require the PR to have the correct signoffs
    # 4.) Require the release to exist and it's end date to be in the future
    # 5.) Require the release already defined on the story, if exists, to match the release we're finishing into
    # 6.) Merge the git branch in to the release (with confirmation)

    if story was queried
      # 7.) Move the story to "QA Pending"
      # 8.) Assign the story to the release it was merged in to

    # 9.) Close the PR
    # 10.) Remove a beta stack if one exists
    # 12.) Remove any docker images for this branch
    # 13.) Remove story codepipeline if one exists
=end

      end
    end
  end
end
