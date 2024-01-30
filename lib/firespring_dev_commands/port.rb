class Port
  attr_accessor :ip, :port

  def initialize(ip, port)
    @ip = ip
    @port = port
  end

  def open?
    Timeout::timeout(1) do
      TCPSocket.new(ip, port).close
      return true
    end

    false
  rescue Timeout::Error,Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    false
  end
end
