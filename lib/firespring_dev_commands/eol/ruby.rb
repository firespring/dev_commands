module Dev
  class EndOfLife
    # Class which parses the Gemfile.lock and
    # returns ProductVersion entities which can be checked for EOL
    class Ruby
      attr_accessor :lock_file, :parsed_lock_file

      def initialize(lock_file:)
        @lock_file = lock_file
        raise 'lock file not specified' if @lock_file.to_s.strip.empty?
        raise 'lock file does not exist' unless File.file?(@lock_file)

        @parsed_lock_file = Bundler::LockfileParser.new(Bundler.read_file(@lock_file))
      end

      # Queries and returns product versions for the default product types
      def default_products
        (gemfile_lock_products).flatten.compact
      end

      # Queries and returns product versions for gemfile lock products
      def gemfile_lock_products
        [].tap do |ary|
          parsed_lock_file.specs.each do |spec|
            product = spec.name
            puts spec.version.inspect
            # TODO: Strip off pieces of the version until it matches?
            version = spec.version.to_s
            name = spec.source.to_s
            ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
          end
        end
      end
    end
  end
end
