require 'osc-ruby'
require 'osc-ruby/em_server'

require 'json'

module Qcmd
  class Server
    attr_accessor :receive_port, :receive_channel, :send_channel, :handler

    def initialize options={}
      self.receive_port    = options[:receive]
      self.receive_channel = OSC::EMServer.new(receive_port)
      self.send_channel    = OSC::Client.new 'localhost', 53000
      self.handler         = Qcmd::Handler.new
    end

    def on message, &callback
      receive_channel.add_method "/#{ message.to_s }", &callback
    end

    def send command, *args
      if %r[^/] =~ command
        address = command
      else
        address = "/#{ command }"
      end

      osc_message = OSC::Message.new address, *args
      self.send_channel.send osc_message
    end

    def run
      on :reply do |message|
        begin
          json = JSON.parse message.to_a.first
          handler.handle json['address'], json['data']
        rescue => ex
          Qcmd.debug "(ERROR: #{ ex.message })"
        end
      end

      Qcmd.debug '(starting server)'
      Thread.new do
        Qcmd.debug '(server is up)'
        receive_channel.run
      end
    end

    def process message
    end
  end
end
