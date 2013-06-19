module OSC
  class Message
    def has_arguments?
      to_a.size > 0
    end

    # attachable responder, for use with TCP::Server
    def responder
      @responder
    end

    def responder=(val)
      @responder = val
    end
  end
end
