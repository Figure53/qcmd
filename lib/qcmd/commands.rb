module Qcmd
  module Commands
    # Commands that expect reponses
    MACHINE_RESPONSE = %w(workspaces)

    WORKSPACE_RESPONSE = %w(
      cueLists selectedCues runningCues runningOrPausedCues connect thump
    )

    # commands that always expect a response
    CUE_RESPONSE = %w(
      uniqueID hasFileTargets hasCueTargets allowsEditingDuration isLoaded
      isRunning isPaused isBroken preWaitElapsed actionElapsed
      postWaitElapsed percentPreWaitElapsed percentActionElapsed
      percentPostWaitElapsed type sliderLevels
      basics children
    )

    # commands that expect a response if given without args
    NO_ARG_CUE_RESPONSE = %w(
      number name notes cueTargetNumber cueTargetId preWait duration
      postWait continueMode flagged armed colorName
      sliderLevel
    )

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
  end
end
