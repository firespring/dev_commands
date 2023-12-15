module Dev
  # Module containing different classes for interfacing with coverage files
  module Coverage
    # Class for checking code coverage using cobertura
    class Cobertura
      attr_reader :local_filename, :container_filename, :filename, :threshold

      def initialize(filename: 'cobertura.xml', threshold: nil, container_path: nil, local_path: nil)
        @filename = filename
        @local_filename = File.join(local_path || '.', @filename)
        @container_filename = File.join(container_path || '.', @filename)
        @threshold = threshold.to_f
      end

      # Remove any previous versions of the local file that will be output
      # return the phpunit options needed to regenerate the cobertura xml file
      def php_options
        # Remove any previous coverage info
        FileUtils.rm_f(local_filename, verbose: true)

        %W(--coverage-cobertura #{container_filename})
      end

      # Parse the cobertura file as a hash and check the total coverage against the desired threshold
      def check
        report = Ox.load(File.read(local_filename), mode: :hash)
        attrs, = report[:coverage]
        cov_pct = attrs[:'line-rate'].to_f * 100
        raise format('Line coverage %.2f%% is less than the threshold %.2f%%', cov_pct, threshold) if cov_pct < threshold

        puts format('Line coverage %.2f%% is above the threshold %.2f%%', cov_pct, threshold)
      end
    end
  end
end
