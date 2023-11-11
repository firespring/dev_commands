require 'firespring_dev_commands'
require 'bundler'
Bundler.require

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.stats_options = ['--list-undoc']
end

Dev::Docker.configure do |c|
  c.min_version = '23.0.0'
end

Dev::Docker::Compose.configure do |c|
  c.max_version = '3.0.0'
end

Dev::Template::Docker::Default.new
Dev::Template::Docker::Application.new('app')
Dev::Template::Docker::Ruby::Application.new('app')

Dev::Git.configure do |c|
  c.min_version = '2.27.0'
end
Dev::Template::Git.new

Dev::EndOfLife.config do |c|
  c.product_versions = [
    Dev::EndOfLife::ProductVersion.new('debian', '11', 'base OS version running in the container we use for test/package'),
    Dev::EndOfLife::ProductVersion.new('docker-engine', '23.0', 'the docker version running in the container we use for test/package'),
    Dev::EndOfLife::ProductVersion.new('ruby', '3.1', 'the version of ruby running in the container we use for test/package')
  ]
end
Dev::Template::Eol.new

desc 'Open the project readme in a browser'
task :docs do
  Launchy.open("https://github.com/firespring/#{Dev::Git.new.info.first.name}/blob/#{Dev::Git.new.branch_name}/README.md")
end

namespace :docs do
  desc 'Generate yardoc and open in a browser'
  task yard: [:yard] do
    Launchy.open("file://#{DEV_COMMANDS_ROOT_DIR}/doc/index.html")
  end
end

desc 'Release new versions of the library'
task release: %i(gem:release) do
  LOG.debug 'Releasing all libraries'
end

# Monkeypatch to scope down the available commands
module Bundler
  class GemHelper
    def install
      built_gem_path = nil

      namespace :gem do
        desc 'Clean up any previously build gems'
        task :clean do
          FileUtils.rm(Dir.glob('**/*.gem'))
        end

        desc "Build #{name}-#{version}.gem into the pkg directory."
        task :build do
          built_gem_path = build_gem
        end

        desc "Build and install #{name}-#{version}.gem into system gems."
        task install: [:build] do
          install_gem(built_gem_path)
        end

        desc "Build and push #{name}-#{version}.gem to #{gem_push_host}"
        task release: %i(app:build app:audit app:lint app:test gem:clean gem:build gem:release:rubygem_push) do
          puts 'Gem released successfully!'
        end

        task 'release:rubygem_push' do
          rubygem_push(built_gem_path) if gem_push?
        end
      end

      GemHelper.instance = self
    end
  end
end
Bundler::GemHelper.install_tasks
