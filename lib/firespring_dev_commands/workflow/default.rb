module Dev
  module Workflow
    class Default < Base
      Config = Struct.new(:prefix, :release_prefix) do
        def initialize
          self.prefix = nil
          self.release_prefix = nil
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

      attr_accessor :prefix, :branch, :branch_name, :release_prefix, :release_branch, :release_name

      def initialize(
        prefix: self.class.config.prefix,
        release_prefix: self.class.config.release_prefix
      )
        @prefix = prefix || 'feature'
        @branch = nil
        @branch_name = nil
        @release_prefix = release_prefix || 'release'
        @release_branch = nil
        @release_name = nil
      end

      def branch
        unless @branch
          @branch = ENV['BRANCH'].to_s.strip
          raise 'Must specify BRANCH as an environment variable' if @branch.strip.empty?
        end

        raise "BRANCH should start with a '#{@prefix}/' prefix" unless @branch.start_with?("#{@prefix}/")

        @branch
      end

      def branch_name
        @branch_name ||= branch.sub(/#{prefix}\//, '')
      end

      def release_branch
        unless @release_branch
          @release_branch = ENV['RELEASE_BRANCH'].to_s.strip
          raise 'Must specify RELEASE_BRANCH as an environment variable' if @release_branch.strip.empty?
        end

        raise "RELEASE_BRANCH should start with a '#{@release_prefix}/' prefix" unless @release_branch.start_with?("#{@release_prefix}/")

        @release_branch
      end

      def release_name
        @release_name ||= release_branch.sub(/#{release_prefix}\//, '')
      end

      def start_desc
        'Perform the "start" workflow'
      end

      def start
        # TODO: Add confirmation
        #Dev::Git.new.create_all
      end

      def review_desc
        'Perform the "review" workflow'
      end

      def review
        # TODO: Add confirmation
        # TODO: Merge in staging branch?
      end

      def delete_desc
        'Perform the "delete" workflow'
      end

      def delete
        # TODO: Add confirmation
        #Dev::Git.new.delete_all
      end

      def finish_desc
        'Perform the "finish" workflow'
      end

      def finish
        # TODO: Add confirmation
        # Need to squash merge
        #Dev::Git.new.merge_all
      end
    end
  end
end
