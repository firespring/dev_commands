module Dev
  # Class containing methods for determining operating system information
  class Os
    attr_accessor :os

    def initialize
      @os = ::RbConfig::CONFIG['host_os']
    end

    # Returns true if the host_os contains windowsy text
    def windows?
      os.match?(/(mingw|mswin|windows)/i)
    end

    # Returns true if the host_os contains darwinsy text
    def darwin?
      os.match?(/(darwin|mac os)/i)
    end

    # Returns true if the host_os contains macsy text
    def mac?
      darwin?
    end

    # Returns true if the host_os contains nixy text
    def nix?
      os.match?(/(linux|bsd|aix|solaris)/i)
    end

    # Returns true if the host_os contains cygwiny text
    def cygwin?
      os.match?(/(cygwin)/i)
    end
  end
end
