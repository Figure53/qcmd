# An OSC TCP server receives and sends on the same socket using the SLIP
# protocol.
#
# http://www.ietf.org/rfc/rfc1055.txt

module OSC
  module TCP
    class Server < OSC::Server
      def initialize port
        @server = TCPServer.new port
        @matchers = []
        @queue = Queue.new
      end

      # run and stop work the same way

    private

      def detector
        @server.listen(5)

        # outer loop manages connections
        loop do
          network   = nil
          buffer    = []
          skip_char = false

          # block until a new connection is opened, then get socket and create a
          # responder so we can .send OSC::Message objects in response
          socket = @server.accept
          responder = SendingSocket.new(socket)

          # fam, port, *addr = socket.getpeername.unpack('nnC4')

          loop do
            c, _network = socket.recvfrom(1)
            network ||= _network

            begin
              case c
              when CHAR_END_ENC
                if buffer.size > 0
                  osc_data = buffer.join

                  if network.nil?
                    # we don't know what port or address the connection is coming from :(
                    ip_info = [0, 'localhost']
                  else
                    ip_info = Array.new
                    ip_info << network[1]
                    ip_info.concat(network[2].split('.'))
                  end

                  # tell listeners that messages have arrived, attach responder
                  OSCPacket.messages_from_network(osc_data, ip_info).each do |message|
                    message.responder = responder
                    @queue.push(message)
                  end

                  # clear buffer and keep listening
                  buffer.clear
                end
              when CHAR_ESC_ENC
                skip_char = true
              when CHAR_ESC_END_ENC
                if skip_char
                  buffer << CHAR_ESC_ENC
                  skip_char = false
                end
              when CHAR_ESC_ESC_ENC
                if skip_char
                  buffer << CHAR_ESC_ENC
                  skip_char = false
                end
              else
                buffer << c
              end
            rescue EOFError
            end
          end
        end
      end
    end
  end
end


