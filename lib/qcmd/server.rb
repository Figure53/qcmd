require 'osc-ruby'
require 'osc-ruby/em_server'

module Qcmd
  class Server
    attr_accessor :port, :listener

    def initialize port
      self.port = port
      self.listener = OSC::EMServer.new(port)
    end

    def on message, &callback
      listener.add_method "/#{ message.to_s }", &callback
    end

    def run
      Thread.new do
        listener.run
      end
    end
  end
end
