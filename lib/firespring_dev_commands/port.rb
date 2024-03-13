module Dev
  # Class containing methods for actions to be taken on ports
  class Port
    attr_accessor :ip_address, :port

    def initialize(ip_address, port)
      @ip_address = ip_address
      @port = port
    end

    # Returns true if the port is open
    # Returns false otherwise
    def open?(timeout = 1)
      Timeout.timeout(timeout) do
        TCPSocket.new(ip_address, port).close
        return true
      end

      false
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      false
    end
  end
end
