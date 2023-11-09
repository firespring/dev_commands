require 'aws-sdk-lambda'
require 'aws-sdk-elasticache'
require 'aws-sdk-rds'
require 'aws-sdk-opensearchservice'

module Dev
  class EndOfLife
    class Aws
      def elasticache_products
        client = ::Aws::ElastiCache::Client.new
        client.describe_cache_clusters.cache_clusters.filter_map do |cluster|
          name = cluster.cache_cluster_id
          product = cluster.engine
          version = cluster.engine_version.reverse.split('.')[-2..].join('.').reverse
          Dev::EndOfLife::ProductVersion.new(product, version, name)
        end
      end

      def lambda_products
        client = ::Aws::Lambda::Client.new
        client.list_functions.functions.filter_map do |function|
          # Runtime is empty if using a docker image
          next unless function.runtime

          name = function.function_name
          product = function.runtime.split(/[0-9]/, 2).first
          version = function.runtime.split(/#{product}/, 2).last.chomp('.x')
          Dev::EndOfLife::ProductVersion.new(product, version, name)
        end
      end

      def opensearch_products
        client = ::Aws::OpenSearchService::Client.new
        client.list_domain_names.domain_names.filter_map do |domain|
          name = domain.domain_name
          product = domain.engine_type
          version = client.describe_domain(domain_name: name).domain_status.engine_version.split('_').last.split('.').first
          Dev::EndOfLife::ProductVersion.new(product, version, name)
        end
      end

      def rds_products
        supported_aws_engines = ['mysql', 'postgresql']
        supported_eol_engines = ['mssqlserver', 'mysql', 'postgresql', 'sqlite']

        client = ::Aws::RDS::Client.new
        client.describe_db_instances.db_instances.filter_map do |instance|
          name = instance.db_instance_identifier
          product = if supported_aws_engines.include?(instance.engine)
                      "amazon-rds-#{instance.engine}"
                    elsif supported_eol_engines.include?(instance.engine)
                      instance.engine
                    else
                      puts "WARNING: unsupported engine #{instance.engine} found".light_yellow
                      next
                    end
          version = instance.engine_version.reverse.split('.')[-2..].join('.').reverse
          Dev::EndOfLife::ProductVersion.new(product, version, name)
        end

        # TODO: Add db cluster info too?
      end
    end
  end
end
