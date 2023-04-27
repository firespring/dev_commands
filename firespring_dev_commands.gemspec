require_relative 'lib/firespring_dev_commands/version'

Gem::Specification.new do |s|
  s.name = 'firespring_dev_commands'
  s.version = Dev::Version::VERSION
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.summary = 'Development environment maintenance command library'
  s.description = 'Ruby library for creating/maintaining your development environment'
  s.homepage = 'https://github.com/firespring/dev-commands-ruby'
  s.required_ruby_version = '>= 2.7'
  s.author = 'Firespring'
  s.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']
  s.license = 'MIT'
  s.email = 'opensource@firespring.com'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_dependency 'activesupport', '~> 7.0.4.0'
  s.add_dependency 'aws-sdk-cloudformation', '~> 1.73.0'
  s.add_dependency 'aws-sdk-codepipeline', '~> 1.54.0'
  s.add_dependency 'aws-sdk-ecr', '~> 1.56.0'
  s.add_dependency 'aws-sdk-s3', '~> 1.117.0'
  s.add_dependency 'aws-sdk-ssm', '~> 1.141.0'
  s.add_dependency 'aws-sdk-sts', '~> 1.7.0'
  s.add_dependency 'colorize', '~> 0.8.0'
  s.add_dependency 'docker-api', '~> 2.2.0'
  s.add_dependency 'dotenv', '~> 2.8.0'
  s.add_dependency 'git', '~> 1.13.1'
  s.add_dependency 'inifile', '~> 3.0.0'
  s.add_dependency 'jira-ruby', '~> 2.3.0'
  s.add_dependency 'libxml-ruby', '3.2.1' # Required to support Windows
  s.add_dependency 'public_suffix', '5.0.0' # Pinned because moving to 5.0.1 causes issues in other projects
  s.add_dependency 'rake', '~> 13.0.0'

  # Dev/Test dependencies
  s.add_development_dependency 'builder', '~> 3.2.4'
  s.add_development_dependency 'bundler-audit', '~> 0.9.0'
  s.add_development_dependency 'rake', '~> 13.0.6'
  s.add_development_dependency 'rspec', '~> 3.11.0'
  s.add_development_dependency 'rubocop', '~> 1.36.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.15.0'
  s.add_development_dependency 'simplecov', '~> 0.21.0'
  s.add_development_dependency 'yard', '~> 0.9.28'
  s.add_development_dependency 'launchy', '~> 2.5.2'
end
