module Dev
  class Common
    # Class which returns information about the current platform
    class Platform
      # Constant containing all supported architectures
      ALLOWED_ARCHITECTURES = %w(linux/arm64 linux/amd64).freeze

      # If an architecture was specified in the ENV, use that. Otherwise auto-deted based of the OS reported architecture
      def architecture
        arch = env_architecture || os_architecture
        raise "Invalid DOCKER_ARCHITECTURE: #{arch}. Allowed architectures are #{ALLOWED_ARCHITECTURES.join(', ')}"
        arch
      end

      # Check to see if a docker architecture has been specified in the ENV
      # If it has, verify the format and the value
      private def env_architecture
        arch = ENV['DOCKER_ARCHITECTURE'].to_s.strip.downcase
        return nil if arch.empty?

        arch = "linux/#{arch}" unless arch.start_with?('linux/')
      end

      # Returns a valid docker architecture based off the RUBY_PLATFORM
      private def os_architecture
        return 'linux/amd64' if RUBY_PLATFORM.match(/x86_64|amd64|x64-mingw/)
        return 'linux/arm64' if RUBY_PLATFORM.match(/arm|aarch64/)
        raise 'Unknown or unsupported architecture'
      end
    end
  end
end
