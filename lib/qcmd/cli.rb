require 'qcmd/server'

require 'readline'

require 'osc-ruby'
require 'osc-ruby/em_server'

module Qcmd
  class CLI
    attr_accessor :server

    def launch options={}
      new options
    end

    def initialize options={}
      # start local listening port
      self.server = Qcmd::Server.new :send => ['localhost', 53000], :receive => 53001

      start
    end

    def start
      server.run

      loop do
        message = Readline.readline('q> ', true)
        args    = message.strip.split
        command = args.shift
        server.send(command, *args)
      end
    end
  end
end
