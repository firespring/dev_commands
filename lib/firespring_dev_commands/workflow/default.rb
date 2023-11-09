module Dev
  module Workflow
    class Default < Base
      Config = Struct.new(:prefix) do
        def initialize
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

      attr_accessor :branch

      def initialize(
        branch: nil
        prefix: self.class.config.prefix
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
      end

      def start
        # TODO: Add confirmation
        #Dev::Git.new.create_branch_all
      end

      def review
        # TODO: Add confirmation
        # TODO: Merge in staging branch?
      end

      def delete
        # TODO: Add confirmation
        #Dev::Git.new.delete_all
      end

      def finish
        # TODO: Add confirmation
        # Need to squash merge
        #Dev::Git.new.merge_all
      end
    end
  end
end
