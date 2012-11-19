require 'readline'

module Qcmd
  module InputCompleter
    # the commands listed here should represent every possible legal command
    ReservedWords = %w[
      connect exit quit workspace workspaces disconnect
    ]

    ReservedWorkspaceWords = %w[
      cueLists selectedCues runningCues runningOrPausedCues thump
      go stop pause resume reset panic disconnect
    ]

    ReservedCueWords = %w[
      cue stop pause resume load preview reset panic loadAt uniqueID
      hasFileTargets hasCueTargets allowsEditingDuration isLoaded isRunning
      isPaused isBroken preWaitElapsed actionElapsed postWaitElapsed
      percentPreWaitElapsed percentActionElapsed percentPostWaitElapsed
      type number name notes cueTargetNumber cueTargetId preWait duration
      postWait continueMode flagged armed colorName basics children
      sliderLevel sliderLevels
    ]

    CompletionProc = Proc.new {|input|
      # puts "input: #{ input }"

      matcher  = /^#{Regexp.escape(input)}/
      commands = ReservedWords.grep(matcher)

      if Qcmd.connected?
        # have selected a machine
        if Qcmd.context.workspace_connected?
          # have selected a workspace
          cue_numbers = Qcmd.context.workspace.cues.map(&:number)
          commands    = commands +
                        cue_numbers.grep(matcher) +
                        ReservedCueWords.grep(matcher) +
                        ReservedWorkspaceWords.grep(matcher)
        else
          # haven't selected a workspace yet
          names           = Qcmd.context.machine.workspace_names
          quoted_names    = names.map {|wn| %["#{wn}"]}
          workspace_names = (names + quoted_names).grep(matcher)
          workspace_names = workspace_names.map {|wsn|
            if / / =~ wsn && /"/ !~ wsn
              # if workspace name has a space and is not already quoted
              %["#{ wsn }"]
            else
              wsn
            end
          }
          commands = commands + workspace_names
        end
      else
        # haven't selected a machine yet
        machine_names = Qcmd::Network.names
        quoted_names = machine_names.map {|mn| %["#{mn}"]}
        names = (quoted_names + machine_names).grep(matcher)
        names = names.map {|wsn|
          if / / =~ wsn && /"/ !~ wsn
            # if workspace name has a space and is not already quoted
            %["#{ wsn }"]
          else
            wsn
          end
        }

        # unquote
        commands = commands + names
      end

      commands
    }
  end
end

if Readline.respond_to?("basic_word_break_characters=")
  Readline.basic_word_break_characters= " \t\n`><=;|&{("
end
Readline.completion_append_character = nil
Readline.completion_case_fold = true
Readline.completion_proc = Qcmd::InputCompleter::CompletionProc
