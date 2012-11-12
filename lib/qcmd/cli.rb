require 'highline/import'

module Qcmd
  class CLI
    attr_accessor :server, :client

    def initialize
      # start local listening port
      self.server = Server.new 53001

      server.on :reply {|message|
        say "<%= color('#{message.ip_address}:#{message.ip_port}', :green) %> #{message.address} <%= color('#{}', #{message.to_a.inspect}) %>"
      }

      self.client = OSC::Client.new 'localhost', 53000
    end

    def start
      while true
        message     = ask '> '
        args        = message.split
        address     = args.shift
        osc_message = OSC::Message.new "/#{ address }", *args
      end
    end
  end
end
