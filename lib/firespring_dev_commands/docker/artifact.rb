module Dev
  class Docker
    class Artifact
      attr_accessor :container_path, :local_path

      def initialize(container_path:, local_path:)
        @container_path = container_path
        @local_path = local_path
      end
    end
  end
end
