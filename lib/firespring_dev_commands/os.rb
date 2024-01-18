#require 'rbconfig'

module Dev
  class Os
    attr_accessor :os

    def initialize
      @os = ::RbConfig::CONFIG['host_os']
    end

    def windows?
      os.match?(/(mingw|mswin|windows)/i)
    end

    def darwin?
      os.match?(/(darwin|mac os)/i)
    end

    def mac?
      darwin?
    end

    def nix?
      os.match?(/(linux|bsd|aix|solaris)/i)
    end

    def cygwin?
      os.match?(/(cygwin)/i)
    end
  end
end
