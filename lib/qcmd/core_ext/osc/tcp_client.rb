# An OSC TCP client sends and receives on the same socket using the SLIP
# protocol.
#
# http://www.ietf.org/rfc/rfc1055.txt

module OSC
  module TCP
    class Client
      def initialize host, port, handler=nil
        @host = host
        @port = port
        @handler = handler
        @socket = TCPSocket.new host, port
        @sending_socket = SendingSocket.new @socket
      end

      def close
        @socket.close unless closed?
      end

      def closed?
        @socket.closed?
      end

      # send an OSC::Message
      def send msg
        @sending_socket.send msg

        # puts "[TCP::Client] sent message: #{ enc_msg.inspect }"

        if block_given? || @handler
          messages = response
          if !messages.nil?
            messages.each do |message|
              # puts "[TCPClient] got message #{ message }"
              if block_given?
                yield message
              else
                @handler.handle message
              end
            end
          else
            # puts "[TCP::Client] response is nil"
          end
        end
      end

      def response
        if received_messages = receive_raw
          received_messages.map do |message|
            OSCPacket.messages_from_network(message)
          end.flatten
        else
          nil
        end
      end

      def to_s
        "#<OSC::TCP::Client:#{ object_id } @host:#{ @host.inspect }, @port:#{ @port.inspect }, @handler:#{ @handler.to_s }>"
      end

      private

      def receive_raw
        received = 0
        messages = []
        buffer   = []
        failed   = false
        received_any = false

        loop do
          begin
            # get a character from the socket, fail if nothing is available
            c = @socket.recv_nonblock(1)

            received_any = true

            case c
            when CHAR_END_ENC
              if received > 0
                # add SLIP encoded message to list
                messages << buffer.join

                # reset state and keep reading from the port until there's
                # nothing left
                buffer.clear
                received = 0
                failed = false
              end
            when CHAR_ESC_ENC
              # get next character, blocking is okay
              c = @socket.recv(1)
              case c
              when CHAR_ESC_END_ENC
                c = CHAR_END_ENC
              when CHAR_ESC_ESC_ENC
                c = CHAR_ESC_ENC
              else
                received += 1
                buffer << c
              end
            else
              received += 1
              buffer << c
            end
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            # If any messages have been received, assume sender is done sending.
            if failed || received_any
              break
            end

            # wait one second to see if the socket might become readable (and a
            # response forthcoming). normal usage is send + wait for response,
            # we have to give QLab a reasonable amount of time in which to respond.

            IO.select([@socket], [], [], 1)
            failed = true
            retry
          end
        end

        if messages.size > 0
          messages
        else
          nil
        end
      end
    end
  end
end

