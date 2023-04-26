module Dev
  # Class instance represents a '.env' file and includes methods to read/write the given filename
  class Env
    require 'pathname'

    attr_accessor :envfile, :data

    def initialize(filename = '.env')
      @envfile = Pathname.new(filename)
      @data = {}
      return unless File.exist?(@envfile)

      File.readlines(@envfile).each do |line|
        key, value = line.split('=')
        @data[key.to_s.strip.to_sym] = value.to_s.strip
      end
    end

    # Get the value of the key from the loaded env data
    def get(key)
      data[key.to_s.strip.to_sym]
    end

    # Set the value of the key in the loaded env data
    def set(key, value)
      data[key.to_s.strip.to_sym] = value.to_s.strip
    end

    # Write the current env data back to the original file
    def write
      File.open(envfile, 'w') do |file|
        data.each do |key, value|
          file.write("#{key}=#{value}\n")
        end
      end
    end
  end
end
