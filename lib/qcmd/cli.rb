require 'readline'
require 'osc-ruby'

module Qcmd
  class CLI
    include Qcmd::Plaintext

    attr_accessor :prompt

    def self.launch options={}
      new(options).start
    end

    def initialize options={}
      Qcmd.debug "[CLI initialize] launching with options: #{options.inspect}"

      Qcmd.context = Qcmd::Context.new

      if options[:machine_given]
        Qcmd.debug "[CLI initialize] autoconnecting to machine #{ options[:machine] }"

        Qcmd.while_quiet do
          connect_to_machine_by_name(options[:machine])
        end

        load_workspaces

        if options[:workspace_given]
          Qcmd.debug "[CLI initialize] autoconnecting to workspace #{ options[:workspace] }"

          Qcmd.while_quiet do
            connect_to_workspace_by_name(options[:workspace], options[:workspace_passcode])
          end

          if options[:command_given]
            split_and_handle options[:command]
            exit
          end
        elsif !connect_default_workspace
          Handler.print_workspace_list
          # end
        end
      end

      # add aliases to input completer
      InputCompleter.add_commands aliases.keys

      self
    end

    def machine
      Qcmd.context.machine
    end

    def reset
      Qcmd.context.reset
    end

    def aliases
      @aliases ||= Qcmd::Aliases.defaults.merge(Qcmd::Configuration.config['aliases'] || {})
    end

    def alias_arg_matcher
      /\$(\d+)/
    end

    def add_alias name, expression
      aliases[name] = Parser.generate(expression)
      InputCompleter.add_command name
      Qcmd::Configuration.update('aliases', aliases)

      aliases[name]
    end

    def replace_args alias_expression, original_expression
      Qcmd.debug "[CLI replace_args] populating #{ alias_expression.inspect } with #{ original_expression.inspect }"

      alias_expression.map do |arg|
        if arg.is_a?(Array)
          replace_args(arg, original_expression)
        elsif (arg.is_a?(Symbol) || arg.is_a?(String)) && alias_arg_matcher =~ arg.to_s
          while alias_arg_matcher =~ arg.to_s
            arg_idx = $1.to_i
            arg_val = original_expression[arg_idx]

            Qcmd.debug "[CLI replace_args] found $#{ arg_idx }, replacing with #{ arg_val.inspect }"

            if arg == :"$#{ arg_idx }"
              # pure symbol replace
              #   alias: [:cue, :$1, :name]
              #   input: [:cname, 25]
              #
              #   result:  :$1 -> 25
              arg = arg_val
            else
              # arg replacement inside string
              #   alias: [:cue, :$1, :name, "hello $2"]
              #   input: [:cname, 25, 26]
              #
              #   result:  :$1 -> 25
              #   result:  "hello $2" -> "hello 26"
              arg = arg.to_s.sub("$#{ arg_idx }", arg_val.to_s)
            end
          end

          arg
        else
          arg
        end
      end
    end

    def expand_alias key, expression
      Qcmd.debug "[CLI expand_alias] using alias of #{ key } with #{ expression.inspect }"

      new_command = aliases[key]

      # observe alias arity
      argument_placeholders = new_command.scan(alias_arg_matcher).uniq.map {|placeholder|
        placeholder[0].sub(/$\$/, '').to_i
      }

      if argument_placeholders.size > 0
        arguments_expected = argument_placeholders.max

        # because expression is alias + arguments, the expression's size should
        # be at least arguments_expected + 1
        if expression.size <= arguments_expected
          print "This custom command expects at least #{ arguments_expected } arguments."
          return
        end
      end

      new_command = Parser.parse(new_command)
      new_command = replace_args(new_command, expression)

      new_command
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

    def connect_machine machine
      if machine.nil?
        print "A valid machine is needed to connect!"
        return
      end

      reset

      Qcmd.context.machine = machine

      # in case this is a reconnection
      Qcmd.context.connect_to_qlab

      # tell QLab to always reply to messages
      response = Qcmd::Action.evaluate('/alwaysReply 1')
      if response.nil? || response.to_s.empty?
        log(:error, %[Failed to connect to QLab machine "#{ machine.name }"])
      elsif response.status == 'ok'
        print %[Connected to machine "#{ machine.name }"]
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
      machine = nil

      # machine name can be found or IPv4 address is given

      if machine_name.nil? || machine_name.to_s.empty?
        machine = nil
      elsif Qcmd::Network.find(machine_name)
        machine = Qcmd::Network.find(machine_name)
      elsif Qcmd::Network::IPV4_MATCHER  =~ machine_name.to_s
        machine = Qcmd::Machine.new(machine_name, machine_name, 53000)
      end

      if machine.nil?
        if machine_name.nil? || machine_name.to_s.empty?
          log(:warning, 'You must include a machine name to connect.')
        else
          log(:warning, 'Sorry, that machine could not be found')
        end

        disconnected_machine_warning
      else
        print "Connecting to machine: #{machine_name}"
        connect_machine machine
      end
    end

    def connect_to_machine_by_index machine_idx
      if machine = Qcmd::Network.find_by_index(machine_idx)
        print "Connecting to machine: #{machine.name}"
        connect_machine machine
      else
        log(:warning, 'Sorry, that machine could not be found')
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
        log(:warning, %[You can't connect to a workspace until you've connected to a machine. ])
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
          log(:warning, "That workspace doesn't seem to exist, try one of the following:")
          Qcmd.context.machine.workspaces.each do |ws|
            log(:warning, %[  "#{ ws.name }"])
          end
        end
      else
        log(:warning, %[You can't connect to a workspace until you've connected to a machine. ])
        disconnected_machine_warning
      end
    end

    def use_workspace workspace
      Qcmd.debug %[[CLI use_workspace] connecting to workspace: "#{workspace.name}"]

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
        log(:error, 'Failed to connect to workspace, bad passcode or no passcode given.')
        Qcmd.context.disconnect_workspace
      elsif reply == 'ok'
        print %[Connected to "#{Qcmd.context.workspace.name}"]
        Qcmd.context.workspace_connected = true
      end

      # if it worked, load cues automatically
      if Qcmd.context.workspace_connected?
        load_cues

        if Qcmd.context.workspace.cue_lists
          print "Loaded #{pluralize Qcmd.context.workspace.cues.size, 'cue'}"
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
          Qcmd.debug "[CLI start] got: #{ cli_input.inspect }"
          next
        end

        # save all commands to log
        Qcmd::History.push(cli_input)

        begin
          split_and_handle(cli_input)
        rescue => ex
          print "Command parser couldn't handle the last command: #{ ex.message }"
          print ex.backtrace
        end
      end
    end

    def split_and_handle cli_input
      if /;/ =~ cli_input
        cli_input.split(';').each do |sub_input|
          handle_input Qcmd::Parser.parse(sub_input.strip)
        end
      else
        handle_input Qcmd::Parser.parse(cli_input)
      end
    end

    # the actual command line interface interactor
    def handle_input args
      if args.all? {|a| a.is_a?(Array)}
        # commands all the way down, just get out of the way
        args.each {|arg|
          Qcmd.debug "calling recursive handle_input on #{ arg.inspect }"
          handle_input(arg)
        }
        return
      else
        command = args[0].to_s
      end

      Qcmd.debug "[CLI handle_input] command: #{ command }; args: #{ args.inspect }"

      # this is where qcmd decides how to handle user input

      case command
      when 'exit', 'quit', 'q'
        print 'exiting...'
        exit 0

      when 'connect'
        Qcmd.debug "[CLI handle_input] connect command received args: #{ args.inspect } :: #{ args.map {|a| a.class.to_s}.inspect}"

        machine_ident = args[1]

        if machine_ident.is_a?(Fixnum)
          # machine "index" will be given with a 1-indexed value instead of the
          # stored 0-indexed value.
          connect_to_machine_by_index machine_ident - 1
        else
          connect_to_machine_by_name machine_ident
        end

        if Qcmd.context.machine_connected?
          load_workspaces

          if !connect_default_workspace
            Handler.print_workspace_list
          end
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
        Qcmd.debug "[CLI handle_input] use command received args: #{ args.inspect }"

        workspace_name = args[1]
        passcode       = args[2]

        Qcmd.debug "[CLI handle_input] using workspace: #{ workspace_name.inspect }"

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
          handle_failed_workspace_command args
          return
        end

        if workspace_command.nil?
          print_wrapped("no workspace command given. available workspace commands
                         are: #{Qcmd::InputCompleter::ReservedWorkspaceWords.join(', ')}")
        else
          reply = send_workspace_command(workspace_command, *args)
          handle_simple_reply reply
        end

      when 'help'
        Qcmd::Commands::Help.print_all_commands

      when 'cues'
        if !Qcmd.context.workspace_connected?
          handle_failed_workspace_command args
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
          handle_failed_workspace_command args
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
        handle_simple_reply reply

        fixate_on_cue(cue_action)

      when 'aliases'
        print centered_text(" Available Custom Commands ", '-')
        print

        aliases.each do |(key, val)|
          print key
          print '    ' + word_wrap(val, :indent => '    ', :preserve_whitespace => true).join("\n")
          print
        end

      when 'alias'
        new_alias = add_alias(args[1].to_s, args[2])
        print %[Added alias for "#{ args[1] }": #{ new_alias }]

      when 'new'
        # create new cue

        if !(args.size == 2 && QLab::Cue::TYPES.include?(args.last.to_s))
          log(:warning, "That cue type can't be created, try one of the following:")
          log(:warning, joined_wrapped(QLab::Cue::TYPES.join(", ")))
        else
          reply = send_workspace_command(command, *args)
          handle_simple_reply reply
        end

      when 'select'
        if args.size == 2
          reply = send_workspace_command "#{ args[0] }/#{ args[1] }"

          if reply.respond_to?(:status) && reply.status == 'ok'
            # cue exists, get name and fixate
            cue_action = Qcmd::CueAction.new([:cue, args[1], :name])
            reply = cue_action.evaluate
            if reply.is_a?(QLab::Reply)
              # something went wrong
              handle_simple_reply reply
            else
              print "Selected #{args[1]} - #{reply}"
              fixate_on_cue(cue_action)
            end
          end
        else
          log(:warning, "The select command should be in the form `select CUE_NUMBER`.")
        end

      # local commands
      when 'sleep'
        if args.size != 2
          log(:warning, "The sleep command expects one argument")
        elsif !(args[1].is_a?(Fixnum) || args[1].is_a?(Float))
          log(:warning, "The sleep command expects a number")
        else
          sleep args[1].to_f
        end

      when 'log-silent'
        @previous_log_level = Qcmd.log_level
        Qcmd.log_level = :none

      when 'log-noisy'
        Qcmd.log_level = @previous_log_level || :info

      when 'log-debug'
        Qcmd.log_level = :debug
        print "set log level to :debug"

      when 'log-info'
        Qcmd.log_level = :info
        print "set log level to :info"

      when 'echo'
        if args[1].is_a?(Array)
          print Action.evaluate(args[1])
        else
          print args[1]
        end

      else
        if aliases[command]
          Qcmd.debug "[CLI handle_input] using alias #{ command }"

          new_expression = expand_alias(command, args)

          # alias expansion failed, go back to CLI
          return if new_expression.nil?

          # unpack nested command. e.g., [[:cue, 1, :name]] -> [:cue, 1, :name]
          if new_expression.size == 1 && new_expression[0].is_a?(Array)
            while new_expression.size == 1 && new_expression[0].is_a?(Array)
              new_expression = new_expression[0]
            end
          end

          Qcmd.debug "[CLI handle_input] expanded to: #{ new_expression.inspect }"

          # recurse!
          if new_expression.all? {|exp| exp.is_a?(Array)}
            new_expression.each {|nested_expression|
              handle_input nested_expression
            }
          else
            handle_input(new_expression)
          end

        elsif Qcmd.context.cue_connected? && Qcmd::InputCompleter::ReservedCueWords.include?(command)
          # prepend the given command with a cue address
          if Qcmd.context.cue.number.nil? || Qcmd.context.cue.number.size == 0
            command_args = [:cue_id, Qcmd.context.cue.id, command]
          else
            command_args = [:cue, Qcmd.context.cue.number, command]
          end

          # add the rest of the given args
          Qcmd.debug "adding #{args[1..-1].inspect} to #{ command_args.inspect }"
          command_args.push(*args[1..-1])

          Qcmd.debug "creating cue action with #{command_args.inspect}"
          cue_action = Qcmd::CueAction.new(command_args)

          reply = cue_action.evaluate
          handle_simple_reply reply

        elsif Qcmd.context.workspace_connected? && Qcmd::InputCompleter::ReservedWorkspaceWords.include?(command)
          reply = send_workspace_command(command, *args)
          handle_simple_reply reply

        else
          # failure modes?
          if %r[/] =~ command
            # might be legit OSC command, try sending
            reply = Qcmd::Action.evaluate(args)
            handle_simple_reply reply
          else
            if Qcmd.context.cue_connected?
              # cue is connected, but command isn't a valid cue command
              print_wrapped("Unrecognized command: '#{ command }'. Try one of these cue commands: #{ Qcmd::InputCompleter::ReservedCueWords.join(', ') }")
              print 'or disconnect from the cue with ..'
            elsif Qcmd.context.workspace_connected?
              # workspace is connected, but command isn't a valid workspace command
              print_wrapped("Unrecognized command: '#{ command }'. Try one of these workspace commands: #{ Qcmd::InputCompleter::ReservedWorkspaceWords.join(', ') }")
            elsif Qcmd.context.machine_connected?
              # send a command directly to a machine
              reply = Qcmd::Action.evaluate(args)
              handle_simple_reply reply
            else
              print 'you must connect to a machine before sending commands'
            end
          end
        end
      end
    end

    def handle_failed_workspace_command command
      command = command.join ' '
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

    def handle_simple_reply reply
      if reply.is_a?(QLab::Reply)
        if !reply.status.nil?
          print reply.status
        end
      else
        render_data reply
      end
    end

    def render_data data
      if data.is_a?(Array) || data.is_a?(Hash)
        begin
          print JSON.pretty_generate(data)
        rescue JSON::GeneratorError
          Qcmd.debug "[CLI render_data] failed to JSON parse data: #{ data.inspect }"
          print data.to_s
        end
      else
        print data.to_s
      end
    end

    def fixate_on_cue cue_action
      # fixate on the cue which is the subject of the given action
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
    end

    def send_workspace_command _command, *args
      if !Qcmd.context.workspace.nil?
        args[0] = "workspace/#{ Qcmd.context.workspace.id }/#{ _command }"
        Qcmd::Action.evaluate(args)
      else
        log(:warning, "A workspace needs to be connected before a workspace command can be sent.")
      end
    end

    ## QLab commands

    def load_workspaces
      if !Qcmd.context.machine.nil?
        Qcmd.context.machine.workspaces = Qcmd::Action.evaluate('workspaces').map {|ws| QLab::Workspace.new(ws)}
      end
    end

    def connect_default_workspace
      connectable = Qcmd.context.machine.workspaces.size == 1 &&
        !Qcmd.context.machine.workspaces.first.passcode? &&
        !Qcmd.context.workspace_connected?
      if connectable
        connect_to_workspace_by_index(0, nil)

        true
      else
        false
      end
    end

    def load_cues
      cues = Qcmd::Action.evaluate('/cueLists')
      Qcmd.context.workspace.cue_lists = cues.map {|cue_list| Qcmd::QLab::CueList.new(cue_list)}
    end
  end
end
