module Dev
  class Docker
    # Contains the local path and container path for and artifact that should be copied back to the user's local systea
    class Artifact
      attr_accessor :container_path, :local_path

      def initialize(container_path:, local_path:)
        @container_path = container_path
        @local_path = local_path
      end
    end
  end
end
