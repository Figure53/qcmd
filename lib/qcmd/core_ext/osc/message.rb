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

    def debug
      types = to_a.map(&:class).map(&:to_s).join(', ')
      args  = to_a

      "#{ip_address}:#{ip_port} -- #{address} -- [#{ types }] -- #{ args.inspect }"
    end
  end
end
