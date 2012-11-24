require 'qcmd/plaintext'

module Qcmd
  module Commands
    # Commands that expect reponses
    MACHINE_RESPONSE = %w(workspaces)

    WORKSPACE_RESPONSE = %w(
      cueLists selectedCues runningCues runningOrPausedCues connect thump
    )

    WORKSPACE_NO_RESPONSE = %w(
      go stop pause resume reset panic
    )

    ALL_WORKSPACE_COMMANDS = [WORKSPACE_RESPONSE + WORKSPACE_NO_RESPONSE]

    # commands that take no args and do not respond
    CUE_NO_RESPONSE = %w(
      start stop pause resume load preview reset panic
    )

    # commands that take args but do not respond
    CUE_ARG_NO_RESPONSE = %w(
      loadAt
    )

    # commands that always expect a response
    CUE_RESPONSE = %w(
      uniqueID hasFileTargets hasCueTargets allowsEditingDuration isLoaded
      isRunning isPaused isBroken preWaitElapsed actionElapsed
      postWaitElapsed percentPreWaitElapsed percentActionElapsed
      percentPostWaitElapsed type sliderLevels
      basics children
    )

    # commands that take args but expect a response if given without args
    NO_ARG_CUE_RESPONSE = %w(
      number name notes cueTargetNumber cueTargetId preWait duration
      postWait continueMode flagged armed colorName
      sliderLevel
    )

    # all cue commands that take arguments
    CUE_ARG = CUE_ARG_NO_RESPONSE + NO_ARG_CUE_RESPONSE

    ALL_CUE_COMMANDS = CUE_NO_RESPONSE +
                       CUE_ARG_NO_RESPONSE +
                       CUE_RESPONSE +
                       NO_ARG_CUE_RESPONSE

    class << self
      def machine_response_matcher
        @machine_response_matcher ||= %r[(#{MACHINE_RESPONSE.join('|')})]
      end
      def machine_response_match command
        !!(machine_response_matcher =~ command)
      end

      def workspace_response_matcher
        @workspace_response_matcher ||= %r[(#{WORKSPACE_RESPONSE.join('|')})]
      end
      def workspace_response_match command
        !!(workspace_response_matcher =~ command)
      end

      def cue_response_matcher
        @cue_response_matcher ||= %r[(#{CUE_RESPONSE.join('|') })]
      end
      def cue_response_match command
        !!(cue_response_matcher =~ command)
      end

      def cue_no_arg_response_matcher
        @cue_no_arg_response_matcher ||= %r[(#{NO_ARG_CUE_RESPONSE.join('|') })]
      end
      def cue_no_arg_response_match command
        !!(cue_no_arg_response_matcher =~ command)
      end

      def expects_reply? osc_message
        address = osc_message.address

        Qcmd.debug "(check #{address} for reply expectation in connection state #{Qcmd.context.connection_state})"

        # debugger

        case Qcmd.context.connection_state
        when :none
          # shouldn't be dealing with OSC messages when unconnected to
          # machine or workspace
          response = false
        when :machine
          # could be workspace or machine command
          response = machine_response_match(address) ||
                     workspace_response_match(address)
        when :workspace
          if is_cue_command?(address)
            Qcmd.debug "- (checking cue command)"
            if osc_message.has_arguments?
              Qcmd.debug "- (with arguments)"
              response = cue_response_match address
            else
              Qcmd.debug "- (without arguments)"
              response = cue_no_arg_response_match(address) ||
                         cue_response_match(address)
            end
          else
            Qcmd.debug "- (checking workspace command)"
            response = workspace_response_match(address) ||
                       machine_response_match(address)
          end
        end

        response.tap {|value|
          msg = value ? "EXPECT REPLY" : "do not expect reply"
          Qcmd.debug "- (#{ msg })"
        }
      end

      def is_cue_command? address
        /cue/ =~ address && !(/Lists/ =~ address || /Cues/ =~ address)
      end

      def is_workspace_command? address
        /workspace/ =~ address && !(%r[cue/] =~ address || %r[cue_id/] =~ address)
      end
    end

    module Help
      class << self

        def print_all_commands
          Qcmd.print %[
#{Qcmd.centered_text(' Available Commands ', '-')}

exit

  close qcmd


connect MACHINE_NAME

  connect to the machine with name MACHINE_NAME


disconnect

  disconnect from the current machine and workspace


use WORKSPACE_NAME [PASSCODE]

  connect to the workspace with name WORKSPACE_NAME using passcode PASSCODE. A
  passcode is only required if the workspace has one enabled.


workspaces

  show a list of the available workspaces for the currently connected machine.


workspace COMMAND [VALUE]

  pass the given COMMAND to the connected workspace. The following commands will
  act on a workspace but will not return a value:

    #{Qcmd.wrapped_text(Qcmd::Commands::WORKSPACE_NO_RESPONSE.sort.join(', '), :indent => '    ').join("\n")}

  And these commands will not act on a workspace, but will return a value
  (usually a list of cues):

    #{Qcmd.wrapped_text((Qcmd::Commands::WORKSPACE_RESPONSE - ['connect']).sort.join(', '), :indent => '    ').join("\n")}

  * Pro Tip: once you are connected to a workspace, you can just use COMMAND
  and leave off "workspace" to quickly send the given COMMAND to the connected
  workspace.


cue NUMBER COMMAND [VALUE [ANOTHER_VALUE ...]]

  send a command to the cue with the given NUMBER.

  NUMBER can be a string or a number, depending on the command.

  COMMAND can be one of:

    #{Qcmd.wrapped_text(Qcmd::Commands::ALL_CUE_COMMANDS.sort.join(', '), :indent => '    ').join("\n")}

  Of those commands, only some accept a VALUE. The following commands, if given
  a value, will update the cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::CUE_ARG.sort.join(', '), :indent => '    ').join("\n")}

  Some cues are Read-Only and will return information about a cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::CUE_RESPONSE.sort.join(', '), :indent => '    ').join("\n")}

  Finally, some commands act on a cue, but don't take a VALUE and don't
  respond:

    #{Qcmd.wrapped_text(Qcmd::Commands::CUE_NO_RESPONSE.sort.join(', '), :indent => '    ').join("\n")}

]
        end
      end

    end
  end
end
