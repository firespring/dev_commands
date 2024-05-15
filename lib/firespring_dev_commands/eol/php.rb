module Dev
  class EndOfLife
    class Php
      def default_products
        composer_products
      end

      def composer_products
        eol = Dev::EndOfLife.new
        major_version_only_products = ['laravel']

        [].tap do |ary|
          lockfile = "#{Dev::Php.new.package_file.reverse.split('.')[-1].reverse}.lock"
          packages = JSON.load(File.open(lockfile))&.fetch('packages')
          packages&.each do |package|
            name = package['name']
            product = if name == 'laravel/framework'
                        'laravel'
                      elsif ['symfony/http-client', 'symfony/mailer', 'symfony/mailchimp-mailer'].include?(name)
                        'symfony'
                      else
                        name
                      end

            # Make sure what we found is supported by the EOL library
            next unless eol.is_product?(product)

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
