module Dev
  class EndOfLife
    # Class which checks for eol packges referenced by the ruby package manager
    class Ruby
      attr_reader :ruby, :lockfile

      def initialize(ruby = Dev::Ruby.new)
        @ruby = ruby
        @lockfile = File.join(ruby.local_path, "#{ruby.package_file.reverse.split('.')[-1].reverse}.lock")
      end

      # Default to Rubygems products
      def default_products
        rubygems_products
      end

      # 1.) Parse the rubygems lock file
      # 2.) Do some package name and version manipulation
      # 3.) Return the product if it looks like something that the EOL library tracks
      def rubygems_products
        eol = Dev::EndOfLife.new
        major_version_only_products = []

        [].tap do |ary|
          packages = Bundler::LockfileParser.new(Bundler.read_file(lockfile)).specs
          packages.each do |package|
            name = package.name
            product = name

            # Make sure what we found is supported by the EOL library
            next unless eol.product?(product)

            version = package.version.to_s.reverse.split('.')[-2..].join('.').reverse.tr('v', '')
            version = version.split('.').first if major_version_only_products.include?(product)
            version.chop! if version.end_with?('.00')
            ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
          end
        end
      end
    end
  end
end
