module Dev
  class EndOfLife
    class Node
      attr_reader :node, :lockfile

      def initialize(node = Dev::Node.new)
        @node = node
        @lockfile = File.join(node.local_path, "#{node.package_file.reverse.split('.')[-1].reverse}-lock.json")
      end

      def default_products
        npm_products
      end

      def npm_products
        eol = Dev::EndOfLife.new
        major_version_only_products = %w(ckeditor vue jquery)

        [].tap do |ary|
          packages = JSON.parse(File.read(lockfile))&.fetch('packages', [])
          packages.each do |key, info|
            name = key.split('node_modules/').last
            product = name

            # Make sure what we found is supported by the EOL library
            next unless eol.product?(product)

            version = info['version'].reverse.split('.')[-2..].join('.').reverse.tr('v', '')
            version = version.split('.').first if major_version_only_products.include?(product)
            version.chop! if version.end_with?('.00')
            ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
          end
        end
      end
    end
  end
end
