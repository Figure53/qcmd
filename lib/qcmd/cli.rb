require 'readline'
require 'osc-ruby'

module Qcmd
  class CLI
    include Qcmd::Plaintext

    attr_accessor :qlab_client, :prompt

    def self.launch options={}
      new options
    end

    def initialize options={}
      Qcmd.debug "(launching with options: #{options.inspect})"

      # start local listening port
      Qcmd.context = Qcmd::Context.new

      if options[:machine_given]
        Qcmd.debug "(autoconnecting to machine #{ options[:machine] })"

        Qcmd.while_quiet do
          connect_to_machine_by_name options[:machine]
        end

        if options[:workspace_given]
          Qcmd.debug "(autoconnecting to workspace #{ options[:machine] })"

          Qcmd.while_quiet do
            connect_to_workspace_by_name options[:workspace], options[:workspace_passcode]
          end

          if options[:command_given]
            handle_input options[:command]
            print %[sent command "#{ options[:command] }"]
            exit 0
          end
        elsif Qcmd.context.machine.workspaces.size == 1 && !Qcmd.context.machine.workspaces.first.passcode?
          connect_to_workspace_by_name Qcmd.context.machine.workspaces.first.name, nil
        end
      end

      start
    end

    def get_prompt
      clock = Time.now.strftime "%H:%M"
      prefix = []

      if Qcmd.context.machine_connected?
        prefix << "[#{ Qcmd.context.machine.name }]"
      end

      if Qcmd.context.workspace_connected?
        prefix << "[#{ Qcmd.context.workspace.name }]"
      end

      if Qcmd.context.cue_connected?
        prefix << "[#{ Qcmd.context.cue.name }]"
      end

      ["#{clock} #{prefix.join(' ')}", "> "]
    end

    def connect machine
      if machine.nil?
        print "A valid machine is needed to connect!"
        return
      end

      Qcmd.context.machine = machine
      Qcmd.context.workspace = nil

      # in case this is a reconnection
      self.qlab_client.close if self.qlab_client

      # get an open connection
      self.qlab_client = OSC::TCPClient.new(machine.address, machine.port, Qcmd::Handler.new)

      # tell QLab to always reply to messages
      send_command('alwaysReply', 1) do |response|
        if response.nil?
          print "FAILED TO CONNECT TO QLAB MACHINE #{ machine.name }"
        elsif response.status == 'ok'
          print "connected to #{ machine.name }"
        end
      end

      send_command 'workspaces'
    end

    def connect_to_machine_by_name machine_name
      if machine = Qcmd::Network.find(machine_name)
        print "connecting to machine: #{machine_name}"
        connect machine
      else
        print 'sorry, that machine could not be found'
      end
    end

    def connect_to_machine_by_index machine_idx
      if machine = Qcmd::Network.find_by_index(machine_idx)
        print "connecting to machine: #{machine.name}"
        connect machine
      else
        print 'sorry, that machine could not be found'
      end
    end

    def connect_to_workspace_by_name workspace_name, passcode
      if Qcmd.context.machine_connected?
        if workspace = Qcmd.context.machine.find_workspace(workspace_name)
          workspace.passcode = passcode
          print "connecting to workspace: #{workspace_name}"
          use_workspace workspace
        else
          print "that workspace doesn't seem to exist. try one of the following:"
          Qcmd.context.machine.workspaces.each do |ws|
            print %[  "#{ ws.name }"]
          end
        end
      else
        print %["#{ workspace_name }" is unavailable, you can't connect to a workspace until you've connected to a machine. ]
        if Qcmd::Network.names.size > 0
          print "try one of the following:"
          Qcmd::Network.names.each do |name|
            print %[  #{ name }]
          end
        else
          print "there are no QLab machines on this network :("
        end
      end
    end

    def use_workspace workspace
      Qcmd.debug %[(connecting to workspace: "#{workspace.name}")]

      # set workspace in context. Will unset later if there's a problem.
      Qcmd.context.workspace = workspace

      # send connect message to QLab to make sure subsequent messages target it
      if workspace.passcode?
        send_command "workspace/#{workspace.id}/connect", "%04i" % workspace.passcode
      else
        send_command "workspace/#{workspace.id}/connect"
      end

      # if it worked, load cues automatically
      if Qcmd.context.workspace_connected?
        load_cues

        if Qcmd.context.workspace.cue_lists
          print "loaded #{pluralize Qcmd.context.workspace.cues.size, 'cue'}"
        end
      end
    end

    def reset
      Qcmd.context.reset
      qlab_client.close
    end

    def start
      loop do
        # blocks the whole Ruby VM
        prefix, char = get_prompt

        Qcmd.print prefix
        cli_input = Readline.readline(char, true)

        if cli_input.nil? || cli_input.size == 0
          Qcmd.debug "(got: #{ cli_input.inspect })"
          next
        end

        # save all commands to log
        Qcmd::History.push(cli_input)

        begin
          handle_input(cli_input)
        rescue Qcmd::Parser::ParserException => ex
          print "command parser couldn't handle the last command: #{ ex.message }"
        end
      end
    end

    # the actual command line interface interactor
    def handle_input cli_input
      args    = Qcmd::Parser.parse(cli_input)
      command = args.shift.to_s

      case command
      when 'exit', 'quit', 'q'
        print 'exiting...'
        exit 0

      when 'connect'
        Qcmd.debug "(connect command received args: #{ args.inspect } :: #{ args.map {|a| a.class.to_s}.inspect})"

        machine_ident = args.shift

        if machine_ident.is_a?(Fixnum)
          # machine "index" will be given with a 1-indexed value instead of the
          # stored 0-indexed value.
          connect_to_machine_by_index machine_ident - 1
        else
          connect_to_machine_by_name machine_ident
        end

      when 'disconnect'
        disconnect_what = args.shift

        if disconnect_what == 'workspace'
          Qcmd.context.disconnect_cue
          Qcmd.context.disconnect_workspace

          qlab_client.handler.print_workspace_list
        elsif disconnect_what == 'cue'
          Qcmd.context.disconnect_cue
        else
          reset
          Qcmd::Network.browse_and_display
        end

      when '..'
        if Qcmd.context.cue_connected?
          Qcmd.context.disconnect_cue
        elsif Qcmd.context.workspace_connected?
          Qcmd.context.disconnect_workspace
        else
          reset
        end

      when 'use'
        Qcmd.debug "(use command received args: #{ args.inspect })"

        workspace_name = args.shift
        passcode       = args.shift

        Qcmd.debug "(using workspace: #{ workspace_name.inspect })"

        if workspace_name
          connect_to_workspace_by_name workspace_name, passcode
        else
          print "No workspace name given. The following workspaces are available:"
          qlab_client.handler.print_workspace_list
        end

      when 'help'
        help_command = args.shift

        if help_command.nil?
          # print help according to current context
          Qcmd::Commands::Help.print_all_commands
        else
          # print command specific help
        end

      when 'cues'
        if !Qcmd.context.workspace_connected?
          handle_failed_workspace_command cli_input
          return
        end

        # reload cues
        load_cues

        Qcmd.context.workspace.cue_lists.each do |cue_list|
          print
          print centered_text(" Cues ", '-')
          printable_cues = []

          add_cues_to_list cue_list, printable_cues, 0

          table ['Number', 'Id', 'Name', 'Type'], printable_cues

          print
        end

      when /^(cue|cue_id)$/
        id_field = $1

        if !Qcmd.context.workspace_connected?
          handle_failed_workspace_command cli_input
          return
        end

        # pull off cue number
        cue_identifier = args.shift
        cue_action     = args.shift

        if cue_identifier.nil?
          print "no cue command given. cue commands should be in the form:"
          print
          print "  > cue NUMBER COMMAND ARGUMENTS"
          print
          print "or"
          print
          print "  > cue_id ID COMMAND ARGUMENTS"
          print
          print_wrapped("available cue commands are: #{Qcmd::Commands::CUE.join(', ')}")
          print
        elsif cue_action.nil?
          send_workspace_command("#{ id_field }/#{ cue_identifier }")
        else
          send_workspace_command("#{ id_field }/#{ cue_identifier }/#{ cue_action }", *args)
        end

      when /copy-([a-zA-Z]+)/
        cue_copy_from = args.shift
        cue_copy_to   = args.shift
        field = $1

        send_command "cue/#{ cue_copy_from }/#{ field }" do |response|
          if (response.data.is_a?(String) ||
              response.data.is_a?(Fixnum) ||
              response.data.is_a?(TrueClass) ||
              response.data.is_a?(FalseClass))

            send_command "cue/#{ cue_copy_to }/#{ field }", response.data do |paste_response|
              if paste_response.status == 'ok'
                print %[copied #{ field } "#{ response.data }" from #{ cue_copy_from } to #{ cue_copy_to }]
              end
            end
          end
        end

      when 'workspaces'
        if !Qcmd.context.machine_connected?
          print 'cannot load workspaces until you are connected to a machine'
          return
        end

        send_command 'workspaces'

      when 'workspace'
        workspace_command = args.shift

        if !Qcmd.context.workspace_connected?
          handle_failed_workspace_command cli_input
          return
        end

        if workspace_command.nil?
          print_wrapped("no workspace command given. available workspace commands
                         are: #{Qcmd::InputCompleter::ReservedWorkspaceWords.join(', ')}")
        else
          send_workspace_command(workspace_command, *args)
        end

      else
        if Qcmd.context.cue_connected? && Qcmd::InputCompleter::ReservedCueWords.include?(command)
          # prepend the given command with a cue address
          if Qcmd.context.cue.number.nil? || Qcmd.context.cue.number.size == 0
            command = "cue_id/#{ Qcmd.context.cue.id }/#{ command }"
          else
            command = "cue/#{ Qcmd.context.cue.number }/#{ command }"
          end

          send_workspace_command(command, *args)
        elsif Qcmd.context.workspace_connected? && Qcmd::InputCompleter::ReservedWorkspaceWords.include?(command)
          send_workspace_command(command, *args)
        else
          # failure modes?
          if %r[/] =~ command
            # might be legit OSC command, try sending
            send_command(command, *args)
          else
            if Qcmd.context.cue_connected?
              print_wrapped("Unrecognized command: '#{ command }'. Try one of these cue commands: #{ Qcmd::InputCompleter::ReservedCueWords.join(', ') }")
              print 'or disconnect from the cue with ..'
            elsif Qcmd.context.workspace_connected?
              print_wrapped("Unrecognized command: '#{ command }'. Try one of these workspace commands: #{ Qcmd::InputCompleter::ReservedWorkspaceWords.join(', ') }")
            elsif Qcmd.context.machine_connected?
              send_command(command, *args)
            else
              print 'you must connect to a machine before sending commands'
            end
          end
        end
      end
    end

    def handle_failed_workspace_command command
      print_wrapped(%[The command, "#{ command }" can't be processed yet. you must
                      first connect to a machine and a workspace
                      before issuing other commands.])
    end

    def add_cues_to_list cue, list, level
      cue.cues.each {|_c|
        name = _c.name

        if level > 0
          name += " " + ("-" * level) + "|"
        end

        list << [_c.number, _c.id, name, _c.type]
        add_cues_to_list(_c, list, level + 1) if _c.has_cues?
      }
    end

    ### communication actions
    private

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

      Qcmd.debug "(sending osc message #{ osc_message.address } #{osc_message.has_arguments? ? 'with' : 'without'} args)"

      if block_given?
        # use given response handler, pass it response as a QLab Reply
        qlab_client.send osc_message do |response|
          Qcmd.debug "([CLI.send_command] converting OSC::Message to QLab::Reply)"
          yield QLab::Reply.new(response)
        end
      else
        # rely on default response handler
        qlab_client.send(osc_message)
      end
    end

    def send_workspace_command _command, *args
      command = "workspace/#{ Qcmd.context.workspace.id }/#{ _command }"
      send_command(command, *args)
    end

    ## QLab commands

    def load_cues
      send_workspace_command 'cueLists'
    end
  end
end
