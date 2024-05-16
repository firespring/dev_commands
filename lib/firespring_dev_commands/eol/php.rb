module Dev
  class EndOfLife
    class Php
      attr_reader :php, :lockfile

      def initialize(php = Dev::Php.new)
        @php = php
        @lockfile = File.join(php.local_path, "#{php.package_file.reverse.split('.')[-1].reverse}.lock")
      end

      def default_products
        composer_products
      end

      def composer_products
        eol = Dev::EndOfLife.new
        major_version_only_products = ['laravel']
        laravel_products = ['laravel/framework']
        symfony_products = ['symfony/http-client', 'symfony/mailer', 'symfony/mailchimp-mailer']

        [].tap do |ary|
          packages = JSON.parse(File.open(lockfile))&.fetch('packages', [])
          packages&.each do |package|
            name = package['name']
            product = if laravel_products.include?(name)
                        'laravel'
                      elsif symfony_products.include?(name)
                        'symfony'
                      else
                        name
                      end

            # Make sure what we found is supported by the EOL library
            next unless eol.product?(product)

            version = package['version'].reverse.split('.')[-2..].join('.').reverse.tr('v', '')
            version = version.split('.').first if major_version_only_products.include?(product)
            version.chop! if version.end_with?('.00')
            ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
          end
        end
      end
    end
  end
end
