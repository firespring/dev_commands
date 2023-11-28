# Start coverage
require 'simplecov'

# Set base coverage dir
SimpleCov.coverage_dir('coverage')

# TODO: Increase coverage
# SimpleCov.minimum_coverage 100
SimpleCov.minimum_coverage 29

# Load library files
require_relative '../lib/firespring_dev_commands'
Bundler.require(:test)

require 'securerandom'
def random(len = nil)
  SecureRandom.hex(len)
end
