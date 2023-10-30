module Dev
  class Common
    # Class which returns information about the current platform
    class Platform
      # Constant containing all supported architectures
      ALLOWED_ARCHITECTURES = %w(arm64 amd64).freeze

      # Normalize the ruby platform to return a docker platform architecture format
      def determine_compute_architecture
        case RUBY_PLATFORM
        when /x86_64|amd64/
          'linux/amd64' # 64-bit Intel/AMD architecture
        when /arm|aarch64/
          'linux/arm64' # ARM architecture
        else
          raise 'Unknown or unsupported architecture'
        end
      end

      # Determine the platform architecture
      # If one was specified in the DOCKER_ARCHITECTURE variable, use it
      # Otherwise, use the RUBY_PLATFORM built-in to auto-detect and architecture
      def architecture
        docker_architecture = ENV['DOCKER_ARCHITECTURE'].to_s.strip.downcase
        if docker_architecture.empty?
          determine_compute_architecture
        else
          raise "Missing 'linux/' prefix in DOCKER_ARCHITECTURE: #{docker_architecture}" unless docker_architecture.start_with?('linux/')

          architecture_name = docker_architecture.split('/')[1]
          unless ALLOWED_ARCHITECTURES.include?(architecture_name)
            raise "Invalid DOCKER_ARCHITECTURE: #{architecture_name}. Allowed architectures are #{ALLOWED_ARCHITECTURES.join(', ')}"
          end

          docker_architecture
        end
      end
    end
  end
end
