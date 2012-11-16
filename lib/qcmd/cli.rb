require 'qcmd/server'

require 'readline'

require 'osc-ruby'
require 'osc-ruby/em_server'

module Qcmd
  class CLI
    include Qcmd::Plaintext

    attr_accessor :server, :prompt

    def self.launch options={}
      new options
    end

    def initialize options={}
      # start local listening port
      Qcmd.context = Qcmd::Context.new

      self.prompt = '> '

      start

      # if local machines have already been detected and only one is available,
      # use it.
      if Qcmd::Network.machines
        if Qcmd::Network.machines.size == 1 && !Qcmd::Network.machines.first.passcode?
          puts "AUTOCONNECT"
          connect Qcmd::Network.machines.first, nil
        end
      end
    end

    def connect machine, passcode
      if machine.nil?
        print "A valid machine is needed to connect!"
        return
      end

      Qcmd.context.machine = machine
      Qcmd.context.workspace = nil

      if server.nil?
        # set client connection and start listening port
        self.server = Qcmd::Server.new :receive => 53001
      else
        # change client connection
        server.connect_to_client
      end
      server.run

      server.load_workspaces

      self.prompt = "#{ machine.name }> "
    end

    def use_workspace workspace
      Qcmd.debug %[(connecting to workspace: "#{workspace.name}")]
      # set workspace in context. Will unset later if there's a problem.
      Qcmd.context.workspace = workspace
      self.prompt = "#{ Qcmd.context.machine.name }:#{ workspace.name }> "

      server.connect_to_workspace workspace
    end

    def reset
      Qcmd.context.reset
      server.stop
      self.prompt = "> "
    end

    def start
      loop do
        # blocks the whole Ruby VM
        message = Readline.readline(prompt, true)

        if message.nil? || message.size == 0
          Qcmd.debug "(got: #{ message.inspect })"
          next
        end

        handle_message(message)
      end
    end

    def handle_message message
      args    = Qcmd::Parser.parse(message)
      command = args.shift

      case command
      when 'exit'
        print 'exiting...'
        exit 0
      when 'connect'
        Qcmd.debug "(connect command received args: #{ args.inspect })"

        machine_name = args.shift
        passcode     = args.shift

        if machine = Qcmd::Network.find(machine_name)
          print "connecting to machine: #{machine_name}"
          connect machine, passcode
        else
          print 'sorry, that machine could not be found'
        end
      when 'disconnect'
        reset
        Qcmd::Network.browse_and_display
      when 'use'
        Qcmd.debug "(use command received args: #{ args.inspect })"

        workspace_name = args.shift.gsub(/['"]/, '')
        passcode       = args.shift

        Qcmd.debug "(using workspace: #{ workspace_name.inspect })"

        if workspace = Qcmd.context.machine.find_workspace(workspace_name)
          workspace.passcode = passcode
          print "connecting to workspace: #{workspace_name}"
          use_workspace workspace
        end
      when 'cues'
        if !Qcmd.context.workspace_connected?
          print "You must be connected to a workspace before you can view a cue list."
        elsif Qcmd.context.workspace.cues
          print
          print centered_text(" Cues ", '-')
          table ['Number', 'Id', 'Name', 'Type'], Qcmd.context.workspace.cues.map {|cue|
            [cue.number, cue.id, cue.name, cue.type]
          }
          print
        end
      when 'cue'
        # pull off cue number
        cue_number = args.shift
        cue_action = args.shift
        args = args.map {|a| a.gsub(/^"/, '').gsub(/"$/, '')}

        if cue_number.nil?
          print "no cue command given. cue commands should be in the form:"
          print
          print "  > cue NUMBER COMMAND ARGUMENTS"
          print
          print wrapped_text("available cue commands are: #{Qcmd::InputCompleter::ReservedCueWords.inspect}")
        elsif cue_action.nil?
          server.send_workspace_command(cue_number)
        else
          server.send_cue_command(cue_number, cue_action, *args)
        end
      when 'workspace'
        workspace_command = args.shift

        if workspace_command.nil?
          print wrapped_text("no workspace command given. available workspace commands are: #{Qcmd::InputCompleter::ReservedWorkspaceWords.inspect}")
        else
          server.send_workspace_command(workspace_command, *args)
        end

      else
        server.send_command(command, *args)
      end
    end

  end
end
