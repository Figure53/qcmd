require 'osc-ruby'
require 'osc-ruby/em_server'
require 'ruby-debug'

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
      @sent_messages_expecting_reply = []
      @received_messages = []
    end

    def connect_to_client
      self.machine = Qcmd.context.machine
      self.send_channel = OSC::Client.new machine.address, machine.port

      Qcmd.debug '(setting up listening connection)'
      listen
    end

    def generic_responding_proc
      proc do |osc_message|
        @received_messages << osc_message

        begin
          Qcmd.debug "(received message: #{ osc_message.address })"
          reply_received QLab::Reply.new(osc_message)
        rescue => ex
          Qcmd.debug "(ERROR #{ ex.message })"
        end
      end
    end

    # initialize
    def listen
      if receive_channel
        Qcmd.debug "(stopping existing server)"
        stop
      end

      self.receive_channel = OSC::EMServer.new(self.receive_port)

      Qcmd.debug "(opening receiving channel: #{ self.receive_channel.inspect })"

      receive_channel.add_method %r{/reply/?(.*)}, &generic_responding_proc
    end

    def replies_expected?
      @sent_messages_expecting_reply.size > 0
    end

    def reply_received reply
      Qcmd.debug "(receiving #{ reply })"

      # update world state
      begin
        @handler.handle reply
      rescue => ex
        print "(ERROR: #{ ex.message })"
      end

      # FIFO
      @sent_messages_expecting_reply.shift

      Qcmd.debug "(#{ @sent_messages_expecting_reply.size } messages awaiting reply)"
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
        # clear expecting reply item, assume it will never arrive
        @sent_messages_expecting_reply.shift
      end
    end

    def send_command command, *args
      options = args.extract_options!

      Qcmd.debug "(building command from command, args, options: #{ command.inspect }, #{ args.inspect }, #{ options.inspect })"

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
      Qcmd.debug "(sending osc message #{ osc_message.address } #{osc_message.has_arguments? ? 'with' : 'without'} args)"

      @sent_messages << osc_message
      if Qcmd::Commands.expects_reply?(osc_message)
        Qcmd.debug "(this command expects a reply)"
        @sent_messages_expecting_reply << osc_message
      end

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

    def send_cue_command number, action, *args
      command = "cue/#{ number }/#{ action }"
      send_workspace_command(command, *args)
    end

    ## QLab commands

    def load_workspaces
      send_command 'workspaces'
    end

    def load_cues
      send_workspace_command 'cueLists'
    end

    def connect_to_workspace workspace
      if workspace.passcode?
        send_command "workspace/#{workspace.id}/connect", workspace.passcode
      else
        send_command "workspace/#{workspace.id}/connect"
      end

      # if it worked, load cues automatically
      if Qcmd.context.workspace
        load_cues
      end
    end
  end
end
