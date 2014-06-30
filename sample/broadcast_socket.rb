require 'rubygems'
require 'osc-ruby'

module OSC
  class Client
    def initialize(host, port)
      @so = UDPSocket.new
      # so we can send broadcast packets
      @so.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      @so.connect(host, port)
    end
  end
end

c = OSC::Client.new '255.255.255.255', 53000
c.send(OSC::Message.new(ARGV[0] || "/go"))
