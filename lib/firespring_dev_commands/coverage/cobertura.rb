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

        report = Ox.load(File.read(local_filename))
        total_covered = total_missed = 0
        report.coverage.locate("packages/package").each do |package|
          filename =  package.attributes[:name]
          line_rate = package.attributes[:'line-rate']
          cobertura_reported_coverage = line_rate.to_f
          cobertura_reported_precision = line_rate.split('.').last.length

          file_covered = file_missed = 0
          file_lines_counted = Set.new()
          package.locate("classes/class/lines/line").each do |line|
            # Don't count lines multiple times
            line_number = line.attributes[:number]
            next if file_lines_counted.include?(line_number)

            file_lines_counted << line_number
            if line.attributes[:hits].to_i.positive?
              file_covered += 1
            else
              file_missed += 1
            end
          end
          file_lines_valid = file_covered + file_missed
          file_coverage = 0.0
          file_coverage = (file_covered.to_f / file_lines_valid).round(cobertura_reported_precision) if file_lines_valid.positive?
          puts "WARNINNG: #{file_coverage} differed from what cobertura reported #{cobertura_reported_coverage}".light_yellow unless file_coverage == cobertura_reported_coverage

          total_covered += file_covered
          total_missed += file_missed
        end
        total_lines_valid = total_covered + total_missed
        total_coverage = 0.0
        total_coverage = (total_covered.to_f / total_lines_valid).round(14) if total_lines_valid.positive?

        puts "Lines missing coverage was #{total_missed}"
        puts "Configured threshold was #{threshold}" if threshold
        raise 'Code coverage not met' if threshold && total_missed > threshold
      end
    end
  end
end
