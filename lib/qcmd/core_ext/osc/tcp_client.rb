# An OSC TCP client sends and receives on the same socket using the SLIP
# protocol.
#
# http://www.ietf.org/rfc/rfc1055.txt

module OSC
  class TCPClient

    CHAR_END     = 0300 # indicates end of packet
    CHAR_ESC     = 0333 # indicates byte stuffing
    CHAR_ESC_END = 0334 # ESC ESC_END means END data byte
    CHAR_ESC_ESC = 0335 # ESC ESC_ESC means ESC data byte

    CHAR_END_ENC     = [0300].pack('C') # indicates end of packet
    CHAR_ESC_ENC     = [0333].pack('C') # indicates byte stuffing
    CHAR_ESC_END_ENC = [0334].pack('C') # ESC ESC_END means END data byte
    CHAR_ESC_ESC_ENC = [0335].pack('C') # ESC ESC_ESC means ESC data byte

    def initialize host, port, handler=nil
      @host = host
      @port = port
      @handler = handler
      @so   = TCPSocket.new host, port
    end

    def close
      @so.close unless closed?
    end

    def closed?
      @so.closed?
    end

    def send_char c
      @so.send [c].pack('C'), 0
    end

    # send an OSC::Message
    def send msg
      enc_msg = msg.encode

      send_char CHAR_END

      enc_msg.bytes.each do |b|
        case b
        when CHAR_END
          send_char CHAR_ESC
          send_char CHAR_ESC_END
        when CHAR_ESC
          send_char CHAR_ESC
          send_char CHAR_ESC_ESC
        else
          send_char b
        end
      end

      send_char CHAR_END

      if block_given? || @handler
        messages = response
        if !messages.nil?
          messages.each do |message|
            if block_given?
              yield message
            else
              @handler.handle message
            end
          end
        end
      end
    end

    def receive_raw
      received = 0
      buffer   = []
      failed   = false

      loop do
        begin
          # get a character from the socket, fail if nothing is available
          c = @so.recv_nonblock(1)
          case c
          when CHAR_END_ENC
            if received > 0
              return buffer.join
            end
          when CHAR_ESC_ENC
            # get next character, blocking is okay
            c = @so.recv(1)
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
          # wait one second to see if the socket might become readable (and a
          # response forthcoming). normal usage is send + wait for response,
          # we have to give QLab a reasonable amount of time in which to respond.
          IO.select([@so], [], [], 1)

          if !failed
            failed = true
            retry
          end

          break
        end
      end

      nil
    end

    def response
      if recv = receive_raw
        OSCPacket.messages_from_network(recv)
      else
        nil
      end
    end
  end
end

