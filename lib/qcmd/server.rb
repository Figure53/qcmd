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
      @sent_messages = []
    end

    def connect_to_client
      self.machine = Qcmd.context.machine
      self.send_channel = OSC::Client.new machine.address, machine.port

      Qcmd.debug '(setting up listening connection)'
      listen
    end

    def generic_responding_proc
      proc do |osc_message|
        Qcmd.debug "(received message: #{ osc_message.to_a.first.inspect })"
        begin
          json = JSON.parse osc_message.to_a.first
          response = @handler.handle json['address'], json['data']
        rescue => ex
          json = nil
          response = nil
          Qcmd.debug "(ERROR: #{ ex.message })"
        end

        message = {
          :json => json,
          :osc => osc_message
        }

        reply_received(message, response)
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

    def replies_expected?
      @sent_messages.any? do |message|
        Qcmd::Commands.expects_reply?(message)
      end
    end

    def reply_received message, response
      Qcmd.debug "(marking reply as received for #{ message.inspect })"

      if @sent_messages.any? {|sent| sent.address == message[:json]['address']}
        Qcmd.debug "(removing message from queue (#{@sent_messages.size} in queue))"

        # remove message from sent queue
        @sent_messages.reject! {|m| m.address == message[:json]['address']}

        Qcmd.debug "(removed message from queue (#{@sent_messages.size} in queue))"
      end
    end

    def wait_for_replies
      begin
        yield

        naps = 0
        while replies_expected? do
          if naps > 20
            # FAILED TO GET RESPONSE
            raise TimeoutError.new
          end

          naps += 1
          sleep 0.1
        end
      rescue TimeoutError => ex
        Qcmd.log "[error: reply timeout]"
      end
    end

    def send_command command, *args
      options = args.extract_options!

      # make sure command is valid OSC Address
      if %r[^/] =~ command
        address = command
      else
        address = "/#{ command }"
      end

      osc_message = OSC::Message.new address, *args

      send_message osc_message
    end

    def send_message osc_message
      @sent_messages << osc_message

      Qcmd.debug "(sending osc message #{ osc_message.address } #{osc_message.has_arguments? ? 'with' : 'without'} args)"

      wait_for_replies do
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

      sleep 0.1

      # if it worked...
      if Qcmd.context.workspace
        load_cues
      end
    end
  end
end
