module Dev
  # Module containing different classes for interfacing with coverage files
  module Coverage
    # Class for checking code coverage using cobertura
    class Cobertura
      attr_reader :local_filename, :container_filename, :filename, :threshold

      def initialize(filename: File.join('coverage', 'cobertura.xml'), threshold: nil, container_path: nil, local_path: nil)
        @filename = filename
        @local_filename = File.join(local_path || '.', @filename)
        @container_filename = File.join(container_path || '.', @filename)
        @threshold = threshold
      end

      # Remove any previous versions of the local file that will be output
      # return the phpunit options needed to regenerate the cobertura xml file
      def php_options
        # Remove any previous coverage info
        FileUtils.rm_f(local_filename, verbose: true)

        # Return the needed php commands to generate the cobertura report
        %W(--coverage-cobertura #{container_filename})
      end

      # Parse the cobertura file as a hash and check the total coverage against the desired threshold
      def check(application: nil)
        # If an application has been specified and the file does not exist locally, attempt to copy it back from the docker container
        if application && !File.exist?(local_filename)
          container = Dev::Docker::Compose.new.container_by_name(application)
          Dev::Docker.new.copy_from_container(container, container_filename, local_filename, required: true)
        end

        # Load the file from disk and parse with ox
        report = Ox.load(File.read(local_filename), mode: :hash)
        _, _, files = report[:coverage]

        covered = missed = 0
        files.dig(:packages, :package)&.each do |_attrs, packages|
          _, _, lines = *packages&.dig(:classes, :class)
          lines&.dig(:lines, :line)&.each do |it|
            it = it&.first if it.is_a?(Array)
            if it&.dig(:hits).to_i.positive?
              covered += 1
            else
              missed += 1
            end
          end
        end

        puts "Lines missing coverage was #{missed}"
        puts "Configured threshold was #{threshold}" if threshold
        raise 'Code coverage not met' if threshold && missed > threshold
      end
    end
  end
end
