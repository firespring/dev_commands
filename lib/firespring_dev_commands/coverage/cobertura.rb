module Dev
  # Module containing different classes for interfacing with coverage files
  module Coverage
    # Class for checking code coverage using cobertura
    class Cobertura < Base
      attr_reader :local_filename, :container_filename, :filename, :threshold, :exclude

      def initialize(filename: File.join('coverage', 'cobertura.xml'), threshold: nil, container_path: nil, local_path: nil, exclude: nil)
        @filename = filename
        @local_filename = File.join(local_path || '.', @filename)
        @container_filename = File.join(container_path || '.', @filename)
        @threshold = threshold
        @exclude = (exclude || []).map do |it|
          next it if it.is_a?(Regex)
          Regex.new(it)
        end
      end

      # Remove any previous versions of the local file that will be output
      # return the phpunit options needed to regenerate the cobertura xml file
      def php_options
        # Remove any previous coverage info
        FileUtils.rm_f(local_filename, verbose: true)

        # Return the needed php commands to generate the cobertura report
        %W(--coverage-cobertura #{container_filename})
      end

      # Parse the cobertura file and check the lines missed against the desired threshold
      def check(application: nil)
        # If an application has been specified and the file does not exist locally, attempt to copy it back from the docker container
        if application && !File.exist?(local_filename)
          container = Dev::Docker::Compose.new.container_by_name(application)
          Dev::Docker.new.copy_from_container(container, container_filename, local_filename, required: true)
        end

        report = Ox.load(File.read(local_filename))
        total_missed = report.coverage.locate('packages/package').sum { |package| parse_package_missed(package) }
        puts "Lines missing coverage was #{total_missed}"
        puts "Configured threshold was #{threshold}" if threshold
        raise 'Code coverage not met' if threshold && total_missed > threshold
      end

      # Go through the package and add up all of the lines that were missed
      # Ignore if the file was in the exlude list
      private def parse_package_missed(package)
        filename =  package.attributes[:name]
        return if exclude.any? { |it| it.match(filename) }

        missed = 0
        lines_processed = Set.new
        package.locate('classes/class/lines/line').each do |line|
          # Don't count lines multiple times
          line_number = line.attributes[:number]
          next if lines_processed.include?(line_number)

          lines_processed << line_number
          missed += 1 unless line.attributes[:hits].to_i.positive?
        end
        total = lines_processed.length

        sanity_check_coverage_against_cobertura_values(package, missed, total)
        missed
      end

      # Calculate the coverage percent based off the numbers we got and compare to the
      # value cobertura reported. This is meant as a sanity check that we are reading the data correctly
      # TODO: This should be removed after the above logic has been vetted
      private def sanity_check_coverage_against_cobertura_values(package, missed, total)
        line_rate = package.attributes[:'line-rate']
        cobertura_reported_coverage = line_rate.to_f
        cobertura_reported_precision = line_rate.split('.').last.length

        file_coverage = 0.0
        file_coverage = ((total - missed).to_f / total).round(cobertura_reported_precision) if total.positive?
        return if file_coverage == cobertura_reported_coverage

        filename = package.attributes[:name]
        puts "WARNINNG: #{filename} coverage (#{file_coverage}) differed from what cobertura reported (#{cobertura_reported_coverage})"
      end
    end
  end
end
