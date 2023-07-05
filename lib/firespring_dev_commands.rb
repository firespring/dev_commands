$stdout.sync = true

# This is the root dir of the application using the firespring_dev_commands libarary
DEV_COMMANDS_ROOT_DIR = File.realpath(File.dirname(caller(1..1).first.split(':')[0]))

# This is the project name of the application using the firespring_dev_commands libarary (the name of the directory it is in)
DEV_COMMANDS_PROJECT_NAME = File.basename(DEV_COMMANDS_ROOT_DIR)

# A reference to the top level object context
DEV_COMMANDS_TOP_LEVEL = self

# Add libdir to the default ruby path
libdir = File.realpath(File.dirname(__FILE__))
$LOAD_PATH.unshift libdir

# Add rootdir to the default ruby path
rootdir = File.realpath(File.dirname(libdir))
$LOAD_PATH.unshift rootdir

# Load all ruby files
# rubocop:disable Lint/RedundantDirGlobSort
Dir.glob("#{libdir}/**/*.rb").sort.each { |file| require file }
# rubocop:enable Lint/RedundantDirGlobSort
