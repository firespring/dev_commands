require_relative 'lib/firespring_dev_commands/version'

Gem::Specification.new do |s|
  s.name = 'firespring_dev_commands'
  s.version = Dev::Version::VERSION
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.summary = 'Development environment maintenance command library'
  s.description = 'Ruby library for creating/maintaining your development environment'
  s.homepage = 'https://github.com/firespring/dev-commands-ruby'
  s.required_ruby_version = '>= 3.1'
  s.author = 'Firespring'
  s.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']
  s.license = 'MIT'
  s.email = 'opensource@firespring.com'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_dependency 'activesupport', '~> 7.1.2'
  s.add_dependency 'aws-sdk-cloudformation', '~> 1.97.0'
  s.add_dependency 'aws-sdk-codepipeline', '~> 1.67.0'
  s.add_dependency 'aws-sdk-ecr', '~> 1.68.0'
  s.add_dependency 'aws-sdk-elasticache', '~> 1.95.0'
  s.add_dependency 'aws-sdk-lambda', '~> 1.113.0'
  s.add_dependency 'aws-sdk-opensearchservice', '~> 1.33.0'
  s.add_dependency 'aws-sdk-rds', '~> 1.208.0'
  s.add_dependency 'aws-sdk-route53', '~> 1.87.0'
  s.add_dependency 'aws-sdk-s3', '~> 1.141.0'
  s.add_dependency 'aws-sdk-ssm', '~> 1.162.0'
  s.add_dependency 'aws-sdk-sts', '~> 1.11.0'
  s.add_dependency 'colorize', '~> 1.1.0'
  s.add_dependency 'docker-api', '~> 2.2.0'
  s.add_dependency 'dotenv', '~> 2.8.1'
  s.add_dependency 'excon', '0.110.0' # Currently pinned because 0.111 was causing a "can't modify frozen Array" error
  s.add_dependency 'faraday-retry', '~> 2.0'
  s.add_dependency 'git', '~> 1.18.0'
  s.add_dependency 'inifile', '~> 3.0.0'
  s.add_dependency 'jira-ruby', '~> 2.3.0'
  s.add_dependency 'octokit', '~> 4.23.0'
  s.add_dependency 'ox', '~> 2.14.17'
  s.add_dependency 'public_suffix', '5.0.4'
  s.add_dependency 'rake', '~> 13.1.0'
  s.add_dependency 'slack-ruby-client', '~> 2.2.0'
end
