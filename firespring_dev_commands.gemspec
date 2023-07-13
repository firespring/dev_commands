require_relative 'lib/firespring_dev_commands/version'

Gem::Specification.new do |s|
  s.name = 'firespring_dev_commands'
  s.version = Dev::Version::VERSION
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.summary = 'Development environment maintenance command library'
  s.description = 'Ruby library for creating/maintaining your development environment'
  s.homepage = 'https://github.com/firespring/dev-commands-ruby'
  s.required_ruby_version = '>= 3.2'
  s.author = 'Firespring'
  s.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']
  s.license = 'MIT'
  s.email = 'opensource@firespring.com'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_dependency 'activesupport', '~> 7.0.6'
  s.add_dependency 'aws-sdk-cloudformation', '~> 1.83.0'
  s.add_dependency 'aws-sdk-codepipeline', '~> 1.59.0'
  s.add_dependency 'aws-sdk-ecr', '~> 1.61.0'
  s.add_dependency 'aws-sdk-s3', '~> 1.127.0'
  s.add_dependency 'aws-sdk-ssm', '~> 1.154.0'
  s.add_dependency 'aws-sdk-sts', '~> 1.10.0'
  s.add_dependency 'colorize', '~> 1.1.0'
  s.add_dependency 'docker-api', '~> 2.2.0'
  s.add_dependency 'dotenv', '~> 2.8.1'
  s.add_dependency 'git', '~> 1.18.0'
  s.add_dependency 'inifile', '~> 3.0.0'
  s.add_dependency 'jira-ruby', '~> 2.3.0'
  s.add_dependency 'libxml-ruby', '4.1.1'
  s.add_dependency 'public_suffix', '5.0.1'
  s.add_dependency 'rake', '~> 13.0.6'
  s.add_dependency 'slack-ruby-client', '~> 2.1.0'
end
