require_relative 'base_interface'

module Dev
  module Template
    # Class contains rake templates for managing your git project
    class Git < Dev::Template::BaseInterface
      # Create the rake task for cloning all defined repos
      def create_clone_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:clone)

            desc 'Make sure all repos are cloned'
            task :clone do
              Dev::Git.new.clone_repos
            end
          end
        end
      end

      # Create the rake task for the git checkout method
      def create_checkout_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:checkout)

            desc 'Checks out a branch for each repo (alias: git:co)' \
                 "\n\tuse BRANCH=abc123 to specify the branch of code you with to switch to (required)" \
                 "\n\tIf the branch does not exist, the configured staging or main branch will be checked out"
            task checkout: %w(init) do
              branch = ENV['BRANCH'].to_s.strip
              raise 'branch is required' if branch.empty?

              Dev::Git.new.checkout_all(branch)
            end

            task co: %w(init checkout) do
              # This is an alias to the checkout command
            end

            d = Dev::Git.new
            [d.main_branch, d.staging_branch].uniq.each do |it|
              desc "Checks out the #{it} branch for each repo (alias: git:co:#{it})"
              task "checkout:#{it}": %w(init) do
                Dev::Git.new.checkout_all(it)
              end

              task "co:#{it}": %W(init checkout:#{it}) do
                # This is an alias to the checkout command
              end
            end
          end
        end
      end

      # Create the rake task for the git pull method
      def create_pull_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:pull)

            desc 'Pulls the latest for each repo'
            task pull: %w(init) do
              Dev::Git.new.pull_all
            end
          end
        end
      end

      # Create the rake task for the git push method
      def create_push_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:push)

            desc 'Pushes the current branch to origin'
            task push: %w(init) do
              Dev::Git.new.push_all
            end
          end
        end
      end

      # Create the rake task for the git reset method
      def create_reset_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:reset)

            desc 'Performs a git reset in each repo'
            task reset: %w(init) do
              Dev::Git.new.reset_all
            end
          end
        end
      end

      # Create the rake task for the git status method
      def create_status_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:status)

            desc 'Perform a "git status" on each repo (alias: git:st)'
            task status: %w(init) do
              Dev::Git.new.status_all
            end

            task st: %w(init status) do
              # This is an alias to the status command
            end
          end
        end
      end

      # Create the rake task for the git merge method
      def create_merge_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:merge)

            desc 'Perform a "git merge" on each repo' \
                 "\n\tuse BRANCH=abc123 to specify the branch of code you with to switch to (required)"
            task merge: %w(init) do
              branch = ENV['BRANCH'].to_s.strip
              raise 'branch is required' if branch.empty?

              Dev::Git.new.merge_all(branch)
            end

            d = Dev::Git.new
            [d.main_branch, d.staging_branch].uniq.each do |it|
              desc "Merge the #{it} branch into each repo"
              task "merge:#{it}": %w(init) do
                Dev::Git.new.merge_all(it)
              end
            end
          end
        end
      end

      # Create the rake task for the git commit status pending task.
      def create_commit_status_pending_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:commit_status)

            namespace :commit_status do
              desc 'Add pending status to commit' \
                   "\n\tuse GITHUB_TOKEN=abc123 enables write options for the check (required)" \
                   "\n\tuse REPOSITORY=abc123 to specify the repository (required)" \
                   "\n\tuse COMMIT_ID=abc123 to specify the commit id of code (required)" \
                   "\n\tuse CONTEXT=abc123 names the check on the PR (optional)" \
                   "\n\tuse TARGET_URL={url} adds 'detail' hyperlink to check on the PR (optional)"
              task :pending do
                status = 'pending'
                token = ENV['GITHUB_TOKEN'].to_s.strip
                repo_org, repo_name = ENV['REPOSITORY'].to_s.strip.split('/')
                commit_id = ENV['COMMIT_ID'].to_s.strip

                raise 'GITHUB_TOKEN is required' unless token
                raise 'REPOSITORY is required' unless repo_name
                raise 'COMMIT_ID is required' unless commit_id

                options = {}
                options[:context] = ENV['CONTEXT'].to_s.strip unless ENV['CONTEXT'].to_s.strip.empty?
                options[:target_url] = ENV['TARGET_URL'].to_s.strip unless ENV['TARGET_URL'].to_s.strip.empty?

                Dev::Git.new.commit_status(token:, repo_name:, commit_id:, status:, repo_org:, options:)
              end
            end
          end
        end
      end

      # Create the rake task for the git commit status success task.
      def create_commit_status_success_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:commit_status)

            namespace :commit_status do
              desc 'Add success status to commit' \
                   "\n\tuse GITHUB_TOKEN=abc123 enables write options for the check (required)" \
                   "\n\tuse REPOSITORY=abc123 to specify the repository (required)" \
                   "\n\tuse COMMIT_ID=abc123 to specify the commit id of code (required)" \
                   "\n\tuse CONTEXT=abc123 names the check on the PR (optional)" \
                   "\n\tuse TARGET_URL={url} adds 'detail' hyperlink to check on the PR (optional)"
              task :success do
                status = 'success'
                token = ENV['GITHUB_TOKEN'].to_s.strip
                repo_org, repo_name = ENV['REPOSITORY'].to_s.strip.split('/')
                commit_id = ENV['COMMIT_ID'].to_s.strip

                raise 'GITHUB_TOKEN is required' unless token
                raise 'REPOSITORY is required' unless repo_name
                raise 'COMMIT_ID is required' unless commit_id

                options = {}
                options[:context] = ENV['CONTEXT'].to_s.strip unless ENV['CONTEXT'].to_s.strip.empty?
                options[:target_url] = ENV['TARGET_URL'].to_s.strip unless ENV['TARGET_URL'].to_s.strip.empty?

                Dev::Git.new.commit_status(token:, repo_name:, commit_id:, status:, repo_org:, options:)
              end
            end
          end
        end
      end

      # Create the rake task for the git commit status error task.
      def create_commit_status_error_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:commit_status)

            namespace :commit_status do
              desc 'Add error status to commit' \
                   "\n\tuse GITHUB_TOKEN=abc123 enables write options for the check (required)" \
                   "\n\tuse REPOSITORY=abc123 to specify the repository (required)" \
                   "\n\tuse COMMIT_ID=abc123 to specify the commit id of code (required)" \
                   "\n\tuse CONTEXT=abc123 names the check on the PR (optional)" \
                   "\n\tuse TARGET_URL={url} adds 'detail' hyperlink to check on the PR (optional)"
              task :error do
                status = 'error'
                token = ENV['GITHUB_TOKEN'].to_s.strip
                repo_org, repo_name = ENV['REPOSITORY'].to_s.strip.split('/')
                commit_id = ENV['COMMIT_ID'].to_s.strip

                raise 'GITHUB_TOKEN is required' unless token
                raise 'REPOSITORY is required' unless repo_name
                raise 'COMMIT_ID is required' unless commit_id

                options = {}
                options[:context] = ENV['CONTEXT'].to_s.strip unless ENV['CONTEXT'].to_s.strip.empty?
                options[:target_url] = ENV['TARGET_URL'].to_s.strip unless ENV['TARGET_URL'].to_s.strip.empty?

                Dev::Git.new.commit_status(token:, repo_name:, commit_id:, status:, repo_org:, options:)
              end
            end
          end
        end
      end

      # Create the rake task for the git commit status failure task.
      def create_commit_status_failure_task!
        # Have to set a local variable to be accessible inside of the instance_eval block
        exclude = @exclude

        DEV_COMMANDS_TOP_LEVEL.instance_eval do
          namespace :git do
            return if exclude.include?(:commit_status)

            namespace :commit_status do
              desc 'Add failure status to commit' \
                   "\n\tuse GITHUB_TOKEN=abc123 enables write options for the check (required)" \
                   "\n\tuse REPOSITORY=abc123 to specify the repository (required)" \
                   "\n\tuse COMMIT_ID=abc123 to specify the commit id of code (required)" \
                   "\n\tuse CONTEXT=abc123 names the check on the PR (optional)" \
                   "\n\tuse TARGET_URL={url} adds 'detail' hyperlink to check on the PR (optional)"
              task :failure do
                status = 'failure'
                token = ENV['GITHUB_TOKEN'].to_s.strip
                repo_org, repo_name = ENV['REPOSITORY'].to_s.strip.split('/')
                commit_id = ENV['COMMIT_ID'].to_s.strip

                raise 'GITHUB_TOKEN is required' unless token
                raise 'REPOSITORY is required' unless repo_name
                raise 'COMMIT_ID is required' unless commit_id

                options = {}
                options[:context] = ENV['CONTEXT'].to_s.strip unless ENV['CONTEXT'].to_s.strip.empty?
                options[:target_url] = ENV['TARGET_URL'].to_s.strip unless ENV['TARGET_URL'].to_s.strip.empty?

                Dev::Git.new.commit_status(token:, repo_name:, commit_id:, status:, repo_org:, options:)
              end
            end
          end
        end
      end
    end
  end
end
