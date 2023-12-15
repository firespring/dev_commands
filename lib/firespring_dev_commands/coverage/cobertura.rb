module Dev
  module Coverage
    class Cobertura
      attr_reader :local_filename, :container_filename, :filename, :threshold

      def initialize(filename: 'cobertura.xml', threshold: nil, container_path: nil, local_path: nil)
        @filename = filename
        @local_filename = File.join(local_path || '.', @filename)
        @container_filename = File.join(container_path || '.', @filename)
        @threshold = threshold.to_f

        # Remove any previous coverage info
        FileUtils.rm_f(local_filename, verbose: true)
      end

      def options
        %W(--coverage-cobertura #{container_filename})
      end

      def check
        report = Ox.load(File.read(local_filename), mode: :hash)
        attrs, sources, packages = report[:coverage]
        cov_pct = attrs[:'line-rate'].to_f * 100
        raise "Line coverage %.2f%% is less than the threshold %.2f%%" % [cov_pct, threshold] if cov_pct < threshold

        puts "Line coverage %.2f%% is above the threshold %.2f%%" % [cov_pct, threshold]
      end
    end
  end
end
