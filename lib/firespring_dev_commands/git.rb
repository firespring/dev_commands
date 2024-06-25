require 'fileutils'
require 'git'
require 'octokit'

module Dev
  # Class for performing git functions
  class Git
    # The default base branch to use
    DEFAULT_MAIN_BRANCH = 'master'.freeze

    # Config object for setting top level git config options
    Config = Struct.new(:main_branch, :staging_branch, :info, :min_version, :max_version) do
      def initialize
        self.main_branch = DEFAULT_MAIN_BRANCH
        self.staging_branch = nil
        self.info = [Dev::Git::Info.new(DEV_COMMANDS_PROJECT_NAME, DEV_COMMANDS_ROOT_DIR)]
        self.min_version = nil
        self.max_version = nil
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

      # Returns the version of the git executable running on the system
      def version
        @version ||= ::Git::Lib.new(nil, nil).current_command_version.join('.')
      end
    end

    attr_accessor :main_branch, :staging_branch, :release_branches, :info, :original_branches

    def initialize(
      main_branch: self.class.config.main_branch,
      staging_branch: self.class.config.staging_branch,
      info: self.class.config.info
    )
      @main_branch = main_branch
      raise 'main branch must be configured' if main_branch.to_s.empty?

      @staging_branch = staging_branch || main_branch
      @info = Array(info)
      raise 'git repositories must be configured' if @info.empty? || !@info.all?(Dev::Git::Info)

      check_version
    end

    # Checks the min and max version against the current git version if they have been configured
    def check_version
      min_version = self.class.config.min_version
      raise "requires git version >= #{min_version} (found #{self.class.version})" if min_version && !Dev::Common.new.version_greater_than(min_version, self.class.version)

      max_version = self.class.config.max_version
      raise "requires git version < #{max_version} (found #{self.class.version})" if max_version && Dev::Common.new.version_greater_than(max_version, self.class.version)
    end

    # Returns all git paths configured in our info
    def project_dirs
      @project_dirs ||= @info.map(&:path).sort
    end

    # Returns the first configured project dire
    def default_project_dir
      project_dirs.first
    end

    # Populates and returns a hash containing the original version of branches
    def original_branches
      @original_branches ||= current_branches
    end

    # Returns a hash of each project repo and the branch that is currently checked out
    def current_branches
      {}.tap do |hsh|
        project_dirs.each do |project_dir|
          next unless File.exist?(project_dir)

          Dir.chdir(project_dir) do
            hsh[project_dir] = branch_name(dir: project_dir)
          end
        end
      end
    end

    # Returns the branch name associated with the given repository
    # Defaults to the current directory
    def branch_name(dir: default_project_dir)
      return unless File.exist?(dir)

      g = ::Git.open(dir)
      g.current_branch || "HEAD detached at #{g.object('HEAD').sha[0..7]}"
    end

    # Returns true if the remote branch exists, false otherwise
    def branch_exists?(project_dir, branch_name)
      ::Git.ls_remote(project_dir)['remotes']["origin/#{branch_name}"]
    end

    # Prints the status of multiple repository directories and displays the results in a nice format
    def status_all
      @success = true
      puts
      puts 'Getting status in each repo'.light_yellow if project_dirs.length > 1
      project_dirs.each do |project_dir|
        next unless File.exist?(project_dir)

        repo_basename = File.basename(File.realpath(project_dir))
        header = "#{repo_basename} (#{original_branches[project_dir]})"
        puts Dev::Common.new.center_pad(header).light_green
        @success &= status(dir: project_dir)
        puts Dev::Common.new.center_pad.light_green
      end
      puts

      raise 'Failed getting status on one or more repositories' unless @success
    end

    # Prints the results of the status command
    # Currently running "git status" instead of using the library because it doesn't do well formatting the output
    def status(dir: default_project_dir)
      return unless File.exist?(dir)

      # NOTE: git library doesn't have a good "status" analog. So just run the standard "git" one
      # splitting and puts'ing to prefix each line with spaces...
      Dir.chdir(dir) { indent `git status` }
    end

    # Returns the name of any repositories which have changes
    def repos_with_changes
      info.filter_map { |it| it.name unless changes(dir: it.path).empty? }
    end

    # Print the changes on the given repo
    # Defaults to the current directory
    def changes(dir: default_project_dir)
      return unless File.exist?(dir)

      Dir.chdir(dir) { `git status --porcelain | grep -v '^?'` }.split("\n").map(&:strip)
    end

    # Print the changes on the given repo using the ruby built-in method... which seems _REALLY_ slow compared to the porcelain version
    # Defaults to the current directory
    def changes_slow(dir: default_project_dir)
      return unless File.exist?(dir)

      s = ::Git.open(dir).status
      s.added.keys.map { |it| " A #{it}" } +
        s.changed.keys.map { |it| " M #{it}" } +
        s.deleted.keys.map { |it| " D #{it}" }
    end

    # Runs a git reset on all given repositories with some additional formatting
    def reset_all
      puts
      puts 'Resetting each repo'.light_yellow if project_dirs.length > 1
      project_dirs.each do |project_dir|
        next unless File.exist?(project_dir)

        repo_basename = File.basename(File.realpath(project_dir))
        header = "#{repo_basename} (#{original_branches[project_dir]})"
        puts Dev::Common.new.center_pad(header).light_green
        reset(dir: project_dir)
        puts Dev::Common.new.center_pad.light_green
      end
      puts
    end

    # Runs a git reset on the given repo
    # Defaults to the current directory
    def reset(dir: default_project_dir)
      return unless File.exist?(dir)

      g = ::Git.open(dir)
      indent g.reset_hard
    end

    # Checks out the given branch in all repositories with some additional formatting
    def checkout_all(branch)
      @success = true
      puts
      puts "Checking out #{branch} in each repo".light_yellow if project_dirs.length > 1
      project_dirs.each do |project_dir|
        next unless File.exist?(project_dir)

        repo_basename = File.basename(File.realpath(project_dir))
        puts Dev::Common.new.center_pad(repo_basename).light_green
        @success &= checkout(branch, dir: project_dir)
        puts Dev::Common.new.center_pad.light_green
      end
      puts

      raise "Failed checking out branch #{branch} one or more repositories" unless @success
    end

    # Checks out the given branch in the given repo
    # Defaults to the current directory
    # optionally raise errors
    def checkout(branch, dir: default_project_dir, raise_errors: false)
      raise 'branch is required' if branch.to_s.strip.empty?
      return unless File.exist?(dir)

      # Make sure the original branch hash has been created before we change anything
      original_branches

      g = ::Git.open(dir)
      g.fetch('origin', prune: true)

      # If the branch we are checking out doesn't exist, check out either the staging branch or the main branch
      actual_branch = branch
      unless branch_exists?(dir, branch)
        actual_branch = [staging_branch, main_branch].uniq.find { |it| branch_exists?(dir, it) }
        puts "Branch #{branch} not found, checking out #{actual_branch} instead".light_yellow
      end

      indent g.checkout(actual_branch)
      indent g.pull('origin', actual_branch)
      true
    rescue ::Git::GitExecuteError => e
      raise e if raise_errors

      print_errors(e.message)
      false
    end

    # Create the given branch in the given repo
    # Defaults to the current directory
    # optionally raise errors
    def create_branch(branch, dir: default_project_dir, raise_errors: false)
      raise 'branch is required' if branch.to_s.strip.empty?
      raise "refusing to create protected branch '#{branch}'" if %w(master develop).any?(branch.to_s.strip)
      return unless File.exist?(dir)

      # Make sure the original branch hash has been created before we change anything
      original_branches

      g = ::Git.open(dir)
      g.fetch('origin', prune: true)

      puts "Fetching the latest changes for base branch \"#{staging_branch}\""
      g.checkout(staging_branch)
      g.pull('origin', staging_branch)

      puts "Creating branch #{branch}, pushing to origin, and updating remote tracking"
      g.branch(branch).checkout
      g.push('origin', branch)
      g.config("branch.#{branch}.remote", 'origin')
      g.config("branch.#{branch}.merge", "refs/heads/#{branch}")
      puts
    rescue ::Git::GitExecuteError => e
      raise e if raise_errors

      print_errors(e.message)
      false
    end

    # Add the given paths to git
    # Defaults to the current directory
    # optionally raise errors
    def add(*paths, dir: default_project_dir, raise_errors: false)
      g = ::Git.open(dir)
      indent g.add(paths)
      true
    rescue ::Git::GitExecuteError => e
      raise e if raise_errors

      print_errors(e.message)
      false
    end

    # Merge the branch into all repositories
    def merge_all(branch)
      @success = true
      puts
      puts "Merging #{branch} into each repo".light_yellow if project_dirs.length > 1
      project_dirs.each do |project_dir|
        next unless File.exist?(project_dir)

        repo_basename = File.basename(File.realpath(project_dir))
        puts Dev::Common.new.center_pad(repo_basename).light_green
        @success &= merge(branch, dir: project_dir)
        puts Dev::Common.new.center_pad.light_green
      end
      puts

      raise "Failed merging branch #{branch} in one or more repositories" unless @success

      push_all
    end

    # Merge the given branch into the given repo
    # Defaults to the current directory
    # optionally raise errors
    def merge(branch, dir: default_project_dir, raise_errors: false)
      raise 'branch is required' if branch.to_s.strip.empty?
      return unless File.exist?(dir)

      # Make sure the original branch hash has been created before we change anything
      original_branches

      g = ::Git.open(dir)
      g.fetch('origin', prune: true)
      raise 'branch does not exist' unless branch_exists?(dir, branch)

      # No need to merge into ourself
      current_branch = branch_name(dir:)
      return true if current_branch == branch

      indent "Merging #{branch} into #{current_branch}"
      indent g.merge(branch)
      true
    rescue ::Git::GitExecuteError => e
      raise e if raise_errors

      print_errors(e.message)
      false
    end

    # Pull the latest in all repositories
    def pull_all
      @success = true
      puts
      puts 'Pulling current branch into each repo'.light_yellow if project_dirs.length > 1
      project_dirs.each do |project_dir|
        next unless File.exist?(project_dir)

        repo_basename = File.basename(File.realpath(project_dir))
        puts Dev::Common.new.center_pad(repo_basename).light_green
        @success &= pull(dir: project_dir)
        puts Dev::Common.new.center_pad.light_green
      end
      puts

      raise 'Failed pulling branch in one or more repositories' unless @success
    end

    # Pull the given repo
    # Defaults to the current directory
    # optionally raise errors
    def pull(dir: default_project_dir, raise_errors: false)
      return unless File.exist?(dir)

      g = ::Git.open(dir)
      g.fetch('origin', prune: true)

      branch = branch_name(dir:)
      indent "Pulling branch #{branch} from origin"
      indent g.pull('origin', branch)
      true
    rescue ::Git::GitExecuteError => e
      raise e if raise_errors

      print_errors(e.message)
      false
    end

    # Push to remote in all repositories
    def push_all
      @success = true
      puts
      puts 'Pushing current branch into each repo'.light_yellow if project_dirs.length > 1
      project_dirs.each do |project_dir|
        next unless File.exist?(project_dir)

        repo_basename = File.basename(File.realpath(project_dir))
        puts Dev::Common.new.center_pad(repo_basename).light_green
        @success &= push(dir: project_dir)
        puts Dev::Common.new.center_pad.light_green
      end
      puts

      raise 'Failed pushing branch in one or more repositories' unless @success
    end

    # Push the given repo
    # Defaults to the current directory
    # optionally raise errors
    def push(dir: default_project_dir, raise_errors: false)
      return unless File.exist?(dir)

      g = ::Git.open(dir)
      g.fetch('origin', prune: true)

      branch = branch_name(dir:)
      indent "Pushing branch #{branch} to origin"
      indent g.push('origin', branch)
      true
    rescue ::Git::GitExecuteError => e
      raise e if raise_errors

      print_errors(e.message)
      false
    end

    # Clones all repositories
    def clone_repos
      info.each { |it| clone_repo(dir: it.path, repo_name: it.name) }
    end

    # Clones the repo_name into the dir
    # Optionally specify a repo_org
    # Optionally specify a branch to check out (defaults to the repository default branch)
    def clone_repo(dir:, repo_name:, repo_org: nil, branch: nil, depth: nil)
      # TODO: Split out the default of 'firespring' into a configuration variable
      repo_org = 'firespring' if repo_org.to_s.strip.empty?

      if Dir.exist?("#{dir}/.git")
        puts "#{dir} already cloned".light_green
        return
      end

      FileUtils.mkdir_p(dir.to_s)

      puts "Cloning #{dir} from #{ssh_repo_url(repo_name, repo_org)}".light_yellow

      opts = {}
      opts[:branch] = branch unless branch.to_s.strip.empty?
      opts[:depth] = depth unless depth.to_s.strip.empty?
      g = ::Git.clone(ssh_repo_url(repo_name, repo_org), dir, opts)
      g.fetch('origin', prune: true)
    end

    def commit_status(token:, repo_name:, branch:, status:, repo_org: nil, options: {})
      # TODO: Split out the default of 'firespring' into a configuration variable
      repo_org = 'firespring' if repo_org.to_s.strip.empty?

      # Set up the GitHub client
      client = Octokit::Client.new(access_token: token)

      # Fetch the latest commit SHA for the given branch
      repo = "#{repo_org}/#{repo_name}"
      ref = "heads/#{branch}"
      sha = client.ref(repo, ref).object.sha

      # Create the commit status
      client.create_status(repo, sha, status, options)
    end

    # Builds an ssh repo URL using the org and repo name given
    def ssh_repo_url(name, org)
      "git@github.com:#{org}/#{name}.git"
    end

    # Split on newlines and add additional padding
    def indent(string, padding: '  ')
      string.to_s.split("\n").each { |line| puts "#{padding}#{line}" }
    end

    # Center the string and pad on either side with the given padding character
    # @deprecated Please use {Dev::Common#center_pad} instead
    def center_pad(string = '', pad: '-', len: 80)
      warn '[DEPRECATION] `Dev::Git#center_pad` is deprecated. Please use `Dev::Common#center_pad` instead.'
      Dev::Common.new.center_pad(string, pad:, len:)
    end

    # Exclude the command from the message and print all error lines
    private def print_errors(message)
      indent message.split('error:')[1..].join
    end
  end
end
