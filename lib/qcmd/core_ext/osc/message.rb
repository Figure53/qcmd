module OSC
  class Message
    def has_arguments?
      to_a.size > 0
    end
  end
end
