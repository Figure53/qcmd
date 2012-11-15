require 'osc-ruby'
require 'osc-ruby/em_server'

require 'json'

module Qcmd
  class TimeoutError < Exception; end

  class Server
    attr_accessor :receive_channel, :receive_thread, :receive_port, :send_channel, :machine

    def initialize *args
      options = args.extract_options!

      self.receive_port = options[:receive]
      connect_to_client

      @handler = Qcmd::Handler.new
    end

    def connect_to_client
      self.machine = Qcmd.context.machine
      self.send_channel = OSC::Client.new machine.address, machine.port

      Qcmd.debug '(setting up listening connection)'
      listen
    end

    def generic_responding_proc
      proc do |message|
        Qcmd.debug "(received message: #{ message.to_a.first.inspect })"
        begin
          json = JSON.parse message.to_a.first
          response = @handler.handle json['address'], json['data']
        rescue => ex
          Qcmd.debug "(ERROR: #{ ex.message })"
        end

        reply_received! response
      end
    end

    # initialize
    def listen
      if receive_channel && receive_thread && receive_thread.alive?
        stop
      end

      self.receive_channel = OSC::EMServer.new(self.receive_port)

      Qcmd.debug "(opening receiving channel: #{ self.receive_channel.inspect })"

      receive_channel.add_method %r{/reply/?(.*)}, &generic_responding_proc
    end

    def reply_received! response
      @response = response
      @reply_received = true
    end

    def wait_for_reply reply_expected=true
      begin
        @reply_received = false

        yield

        if reply_expected
          # block until reply received or server times out
          naps = 0
          loop do
            if @reply_received
              break
            end

            if naps > 50
              # FAILED TO GET RESPONSE
              raise TimeoutError.new
            end

            naps += 1
            sleep 0.1
          end
        end
      rescue TimeoutError => ex
        Qcmd.log "[error: reply timeout]"
      end
    end

    def send_command command, *args
      options = args.extract_options!

      if %r[^/] =~ command
        address = command
      else
        address = "/#{ command }"
      end

      wait_for_reply do
        osc_message = OSC::Message.new address, *args
        send_channel.send osc_message
      end
    end

    def stop
      Thread.kill(receive_thread) if receive_thread.alive?
    end

    def run
      Qcmd.debug '(starting server)'
      self.receive_thread = Thread.new do
        Qcmd.debug '(server is up)'
        receive_channel.run
      end
    end
    alias :start :run

    def send_workspace_command _command, *args
      command = "workspace/#{ Qcmd.context.workspace.id }/#{ _command }"
      send_command(command, *args)
    end

    ## QLab commands

    def load_workspaces
      send_command 'workspaces'
    end

    def load_cues
      send_workspace_command 'cueLists'
    end

    def connect_to_workspace workspace
      send_command "workspace/#{workspace.id}/connect"

      # if it worked...
      if Qcmd.context.workspace
        load_cues
      end
    end
  end
end
