module OSC
  class Client
    alias :send_without_logging :send

    def send message
      # Qcmd.debug "SENDING MESSAGE on #{ @so.inspect } :: #{ message.debug }"
      send_without_logging message
    end
  end
end
