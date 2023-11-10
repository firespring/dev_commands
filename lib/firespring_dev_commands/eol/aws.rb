require 'aws-sdk-lambda'
require 'aws-sdk-elasticache'
require 'aws-sdk-rds'
require 'aws-sdk-opensearchservice'

module Dev
  class EndOfLife
    class Aws
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

      def lambda_products
        client = ::Aws::Lambda::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :list_functions) do |response|
            response.functions.each do |function|
              # Runtime is empty if using a docker image
              # TODO Should we still handle this case?
              next unless function.runtime

              name = function.function_name
              product = function&.runtime&.split(/[0-9]/, 2)&.first
              version = function&.runtime&.split(/#{product}/, 2)&.last&.chomp('.x')
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end

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

      def rds_products
        _rds_instances + _rds_clusters
      end

      def _rds_instances
        aws_engines = %w(mysql postgresql)
        client = ::Aws::RDS::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :describe_db_instances) do |response|
            response.db_instances.each do |instance|
              name = instance.db_instance_identifier
              engine = instance.engine.tr('aurora-', '')
              product = if aws_engines.include?(engine)
                          "amazon-rds-#{engine}"
                        else
                          engine
                        end
              version = instance.engine_version.reverse.split('.')[-2..].join('.').reverse
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end

      def _rds_clusters
        aws_engines = %w(mysql postgresql)
        client = ::Aws::RDS::Client.new

        [].tap do |ary|
          Dev::Aws.each_page(client, :describe_db_clusters) do |response|
            response.db_clusters.each do |cluster|
              name = cluster.db_cluster_identifier
              engine = cluster.engine.tr('aurora-', '')
              product = if aws_engines.include?(engine)
                          "amazon-rds-#{engine}"
                        else
                          engine
                        end
              version = cluster.engine_version.reverse.split('.')[-2..].join('.').reverse
              ary << Dev::EndOfLife::ProductVersion.new(product, version, name)
            end
          end
        end
      end
    end
  end
end
