require 'readline'
require 'osc-ruby'

module Qcmd
  class CLI
    include Qcmd::Plaintext

    attr_accessor :prompt

    def self.launch options={}
      new options
    end

    def initialize options={}
      Qcmd.debug "(launching with options: #{options.inspect})"

      Qcmd.context = Qcmd::Context.new

      if options[:machine_given]
        Qcmd.debug "(autoconnecting to machine #{ options[:machine] })"

        Qcmd.while_quiet do
          connect_to_machine_by_name(options[:machine])
        end

        if options[:workspace_given]
          Qcmd.debug "(autoconnecting to workspace #{ options[:machine] })"

          Qcmd.while_quiet do
            connect_to_workspace_by_name(options[:workspace], options[:workspace_passcode])
          end

          if options[:command_given]
            handle_input options[:command]
            print %[sent command "#{ options[:command] }"]
            exit 0
          end
        elsif Qcmd.context.machine.workspaces.size == 1 && !Qcmd.context.machine.workspaces.first.passcode?
          connect_to_workspace_by_index(0, nil)
        end
      end

      start
    end

    def machine
      Qcmd.context.machine
    end

    def reset
      Qcmd.context.reset
    end

    def aliases
      []
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
        prefix << "[#{ Qcmd.context.cue.number } #{ Qcmd.context.cue.name }]"
      end

      ["#{clock} #{prefix.join(' ')}", "> "]
    end

    def connect machine
      if machine.nil?
        print "A valid machine is needed to connect!"
        return
      end

      reset

      Qcmd.context.machine = machine

      # in case this is a reconnection
      Qcmd.context.connect_to_qlab

      # tell QLab to always reply to messages
      response = Qcmd::Action.evaluate('alwaysReply 1')
      if response.nil? || response.empty?
        print "FAILED TO CONNECT TO QLAB MACHINE #{ machine.name }"
      elsif response.status == 'ok'
        print "connected to #{ machine.name }"
      end

      machine.workspaces = Qcmd::Action.evaluate('workspaces').map {|ws| QLab::Workspace.new(ws)}

      if Qcmd.context.machine.workspaces.size == 1 && !Qcmd.context.machine.workspaces.first.passcode?
        connect_to_workspace_by_index(0, nil)
      else
        Handler.print_workspace_list
      end
    end

    def disconnected_machine_warning
      if Qcmd::Network.names.size > 0
        print "Try one of the following:"
        Qcmd::Network.names.each do |name|
          print %[  #{ name }]
        end
      else
        print "There are no QLab machines on this network :("
      end
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

    def connect_to_workspace_by_index workspace_idx, passcode
      if Qcmd.context.machine_connected?
        if workspace = Qcmd.context.machine.workspaces[workspace_idx]
          connect_to_workspace_by_name workspace.name, passcode
        else
          print "That workspace isn't on the list."
        end
      else
        print %[You can't connect to a workspace until you've connected to a machine. ]
        disconnected_machine_warning
      end
    end

    def connect_to_workspace_by_name workspace_name, passcode
      if Qcmd.context.machine_connected?
        if workspace = Qcmd.context.machine.find_workspace(workspace_name)
          workspace.passcode = passcode
          print "Connecting to workspace: #{workspace_name}"

          use_workspace workspace
        else
          print "That workspace doesn't seem to exist, try one of the following:"
          Qcmd.context.machine.workspaces.each do |ws|
            print %[  "#{ ws.name }"]
          end
        end
      else
        print %[You can't connect to a workspace until you've connected to a machine. ]
        disconnected_machine_warning
      end
    end

    def use_workspace workspace
      Qcmd.debug %[(connecting to workspace: "#{workspace.name}")]

      # set workspace in context. Will unset later if there's a problem.
      Qcmd.context.workspace = workspace

      # send connect message to QLab to make sure subsequent messages target it
      if workspace.passcode?
        ws_action_string = "workspace/#{workspace.id}/connect %04i" % workspace.passcode
      else
        ws_action_string = "workspace/#{workspace.id}/connect"
      end

      reply = Qcmd::Action.evaluate(ws_action_string)

      if reply == 'badpass'
        print 'failed to connect to workspace, bad passcode or no passcode given'
        Qcmd.context.disconnect_workspace
      elsif reply == 'ok'
        print 'connected to workspace'
        Qcmd.context.workspace_connected = true
      end

      # if it worked, load cues automatically
      if Qcmd.context.workspace_connected?
        load_cues

        if Qcmd.context.workspace.cue_lists
          print "loaded #{pluralize Qcmd.context.workspace.cues.size, 'cue'}"
        end
      end
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
        rescue => ex
          print "command parser couldn't handle the last command: #{ ex.message }"
          print ex.backtrace
        end
      end
    end

    # the actual command line interface interactor
    def handle_input cli_input
      args    = Qcmd::Parser.parse(cli_input)
      command = args[0].to_s

      case command
      when 'exit', 'quit', 'q'
        print 'exiting...'
        exit 0

      when 'connect'
        Qcmd.debug "(connect command received args: #{ args.inspect } :: #{ args.map {|a| a.class.to_s}.inspect})"

        machine_ident = args[1]

        if machine_ident.is_a?(Fixnum)
          # machine "index" will be given with a 1-indexed value instead of the
          # stored 0-indexed value.
          connect_to_machine_by_index machine_ident - 1
        else
          connect_to_machine_by_name machine_ident
        end

      when 'disconnect'
        disconnect_what = args[1]

        if disconnect_what == 'workspace'
          Qcmd.context.disconnect_cue
          Qcmd.context.disconnect_workspace

          Handler.print_workspace_list
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

        workspace_name = args[1]
        passcode       = args[2]

        Qcmd.debug "(using workspace: #{ workspace_name.inspect })"

        if workspace_name
          if workspace_name.is_a?(Fixnum)
            # decrement given idx
            connect_to_workspace_by_index workspace_name - 1, passcode
          else
            connect_to_workspace_by_name workspace_name, passcode
          end
        else
          print "No workspace name given. The following workspaces are available:"
          Handler.print_workspace_list
        end

      when 'workspaces'
        if !Qcmd.context.machine_connected?
          disconnected_machine_warning
        else
          machine.workspaces = Qcmd::Action.evaluate(args).map {|ws| QLab::Workspace.new(ws)}
          Handler.print_workspace_list
        end

      when 'workspace'
        workspace_command = args[1]

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
          print centered_text(" Cues: #{ cue_list.name } ", '-')
          printable_cues = []

          add_cues_to_list cue_list, printable_cues, 0

          table ['Number', 'Id', 'Name', 'Type'], printable_cues

          print
        end

      when /^(cue|cue_id)$/
        # id_field = $1

        if !Qcmd.context.workspace_connected?
          handle_failed_workspace_command cli_input
          return
        end

        if args.size < 3
          print "Cue commands should be in the form:"
          print
          print "  > cue NUMBER COMMAND [ARGUMENTS]"
          print
          print "or"
          print
          print "  > cue_id ID COMMAND [ARGUMENTS]"
          print
          print_wrapped("available cue commands are: #{Qcmd::Commands::CUE.join(', ')}")
          print
          return
        end

        cue_action = Qcmd::CueAction.new(args)

        reply = cue_action.evaluate

        if reply.is_a?(QLab::Reply)
          if !reply.status.nil?
            print reply.status
          end
        else
          render_data reply
        end

        # fixate on cue
        if Qcmd.context.workspace.has_cues?
          _cue = Qcmd.context.workspace.cues.find {|cue|
            case cue_action.id_field
            when :cue
              cue.number.to_s == cue_action.identifier.to_s
            when :cue_id
              cue.id.to_s == cue_action.identifier.to_s
            end
          }

          if _cue
            Qcmd.context.cue = _cue
            Qcmd.context.cue_connected = true

            Qcmd.context.cue.sync
          end
        end

      when /copy-([a-zA-Z]+)/
        cue_copy_from = args[1]
        cue_copy_to   = args[2]
        field = $1

        protected_fields = %w(
          allowsEditingDuration
          defaultName
          displayName
          hasCueTargets
          hasCueTargets
          hasFileTargets
          hasFileTargets
          isBroken
          isLoaded
          isPaused
          isRunning
          listName
          number
          percentActionElapsed
          percentPostWaitElapsed
          percentPreWaitElapsed
          preWaitElapsed
          type
          uniqueID
        )

        if protected_fields.include?(field)
          print "the \"#{ field }\" field is not copyable"
        else
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
        end

      else
        if aliases.include?(command)
          Qcmd.debug "using alias #{ command }"

        elsif Qcmd.context.cue_connected? && Qcmd::InputCompleter::ReservedCueWords.include?(command)
          # prepend the given command with a cue address
          if Qcmd.context.cue.number.nil? || Qcmd.context.cue.number.size == 0
            command = "cue_id/#{ Qcmd.context.cue.id }/#{ command }"
          else
            command = "cue/#{ Qcmd.context.cue.number }/#{ command }"
          end

          args = [command].push(*args[1..-1])

          cue_action = Qcmd::CueAction.new(args)

          reply = cue_action.evaluate

          if reply.is_a?(QLab::Reply)
            if !reply.status.nil?
              print reply.status
            end
          else
            render_data reply
          end

          # send_workspace_command(command, *args)
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

    def render_data data
      if data.is_a?(Array) || data.is_a?(Hash)
        begin
          print JSON.pretty_generate(data)
        rescue JSON::GeneratorError
          Qcmd.debug "([Handler#handle /cue] failed to JSON parse data: #{ data.inspect })"
          print data.to_s
        end
      else
        print data.to_s
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

      Qcmd.debug "(sending osc message #{ osc_message.address } #{osc_message.has_arguments? ? 'with' : 'without'} args)"

      if block_given?
        # use given response handler, pass it response as a QLab Reply
        Qcmd.context.qlab.send osc_message do |response|
          Qcmd.debug "([CLI.send_command] converting OSC::Message to QLab::Reply)"
          yield QLab::Reply.new(response)
        end
      else
        # rely on default response handler
        Qcmd.context.qlab.send(osc_message)
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
