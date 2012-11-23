module OSC
  class StoppingServer < Server
    def initialize *args
      @state = :initialized
      super(*args)
    end

    def run
      @state = :starting
      super
    end

    def stop
      @state = :stopping
      stop_detector
      stop_dispatcher
    end

  private

    def stop_detector
      # send listening port a "CLOSE" signal on the open UDP port
      _closer = UDPSocket.new
      _closer.connect('', @port)
      _closer.puts "CLOSE-#{@port}"
      _closer.close unless _closer.closed? || !_closer.respond_to?(:close)
    end

    def stop_dispatcher
      @queue << :stop
    end

    def dispatcher
      loop do
        mesg = @queue.pop
        dispatch_message( mesg )
      end
    rescue StopException
      @state == :stopped
    end

    def dispatch_message message
      if message.is_a?(Symbol) && message.to_s == 'stop'
        raise StopException.new
      end

      super(message)
    end

    def detector
      @state = :listening

      loop do
        osc_data, network = @socket.recvfrom( 16384 )

        # quit if socket receives the close signal
        if osc_data == "CLOSE-#{@port}"
          @socket.close if !@socket.closed? && @socket.respond_to?(:close)
          break
        end

        unpack_socket_receipt osc_data, network
      end
    end

    def unpack_socket_receipt osc_data, network
      ip_info = Array.new
      ip_info << network[1]
      ip_info.concat(network[2].split('.'))
      OSC::OSCPacket.messages_from_network( osc_data, ip_info ).each do |message|
        @queue.push(message)
      end
    rescue EOFError
      # pass
    end
  end

  class StopException < Exception; end
end
