require 'logger'

# Only define LOG if it doesn't already exist
unless defined? LOG
  LOG = Logger.new($stdout)
  LOG.formatter = proc { |_, _, _, msg| "#{msg}\n" }
  LOG.level = Logger::DEBUG
end
