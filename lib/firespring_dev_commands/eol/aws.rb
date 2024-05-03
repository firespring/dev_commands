require 'aws-sdk-lambda'
require 'aws-sdk-elasticache'
require 'aws-sdk-rds'
require 'aws-sdk-opensearchservice'

module Dev
  class EndOfLife
    # Class which queries several different AWS product types and
    # returns ProductVersion entities which can be checked for EOL
    class Aws
      # Queries and returns product versions for the default product types
      def default_products
        (elasticache_products + lambda_products + opensearch_products + rds_products).flatten.compact
      end

      # Queries and returns product versions for elasticache products
      def elasticache_products
        client = ::Aws::ElastiCache::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :describe_cache_clusters) do |response|
            response.cache_clusters.each do |cluster|
              name = cluster.cache_cluster_id
              product = cluster.engine
              version = cluster.engine_version.reverse.split('.')[-2..].join('.').reverse
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end

      # Queries and returns product versions for lambda products
      def lambda_products
        client = ::Aws::Lambda::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :list_functions) do |response|
            response.functions.each do |function|
              # Runtime is empty if using a docker image
              next unless function.runtime

              name = function.function_name
              product = function&.runtime&.split(/[0-9]/, 2)&.first
              version = function&.runtime&.split(/#{product}/, 2)&.last&.chomp('.x')
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end

      # Queries and returns product versions for opensearch products
      def opensearch_products
        client = ::Aws::OpenSearchService::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :list_domain_names) do |response|
            response.domain_names.each do |domain|
              name = domain.domain_name
              product = domain.engine_type
              version = client.describe_domain(domain_name: name).domain_status.engine_version.split('_').last.split('.').first
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end

      # Queries and returns product versions for rds products
      def rds_products
        rds_instance_products + rds_cluster_products
      end

      # Queries and returns product versions for rds instance products
      def rds_instance_products
        aws_engines = %w(mysql postgresql)
        aws_sqlserver_engines = %w(sqlserver-ee sqlserver-ex sqlserver-se sqlserver-web)
        client = ::Aws::RDS::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :describe_db_instances) do |response|
            response.db_instances.each do |instance|
              name = instance.db_instance_identifier
              engine = instance.engine.gsub('aurora-', '')
              product = if aws_engines.include?(engine)
                          "amazon-rds-#{engine}"
                        elsif aws_sqlserver_engines.include?(engine)
                          'mssqlserver'
                        else
                          engine
                        end
              version = instance.engine_version.reverse.split('.')[-2..].join('.').reverse
              version.chop! if version.end_with?('.00')
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end

      # Queries and returns product versions for rds cluster products
      def rds_cluster_products
        aws_engines = %w(mysql postgresql)
        aws_sqlserver_engines = %w(sqlserver-ee sqlserver-ex sqlserver-se sqlserver-web)
        client = ::Aws::RDS::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :describe_db_clusters) do |response|
            response.db_clusters.each do |cluster|
              name = cluster.db_cluster_identifier
              engine = cluster.engine.gsub('aurora-', '')
              product = if aws_engines.include?(engine)
                          "amazon-rds-#{engine}"
                        elsif aws_sqlserver_engines.include?(engine)
                          'mssqlserver'
                        else
                          engine
                        end
              version = cluster.engine_version.reverse.split('.')[-2..].join('.').reverse
              version.chop! if version.end_with?('.00')
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end
    end
  end
end
