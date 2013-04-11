require 'qcmd/plaintext'

module Qcmd
  module Commands
    # All Commands
    #
    # *_RESPONSE lists are commands that expect responses
    #

    MACHINE = %w(
      alwaysReply
      connect
      workingDirectory
      workspaces
    )

    WORKSPACE = %w(
      cueLists
      go
      hardStop
      new
      panic
      pause
      reset
      resume
      runningCues
      runningOrPausedCues
      select
      selectedCues
      stop
      thump
      toggleFullScreen
      updates
    )

    # commands that take no args and do not respond
    CUE = %w(
      actionElapsed
      allowsEditingDuration
      armed
      basics
      children
      colorName
      continueMode
      cueTargetId
      cueTargetNumber
      defaultName
      displayName
      duration
      fileTarget
      flagged
      hardStop
      hasCueTargets
      hasFileTargets
      isBroken
      isLoaded
      isPaused
      isRunning
      listName
      load
      loadAt
      name
      notes
      number
      panic
      pause
      percentActionElapsed
      percentPostWaitElapsed
      percentPreWaitElapsed
      postWait
      postWaitElapsed
      preWait
      preWaitElapsed
      preview
      reset
      resume
      sliderLevel
      sliderLevels
      start
      stop
      togglePause
      type
      uniqueID
      valuesForKeys
    )

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
  act on a workspace:

    #{Qcmd.wrapped_text(Qcmd::Commands::WORKSPACE.sort.join(', '), :indent => '    ').join("\n")}

  * Pro Tip: once you are connected to a workspace, you can just use COMMAND
  and leave off "workspace" to quickly send the given COMMAND to the connected
  workspace.

cue NUMBER COMMAND [VALUE [ANOTHER_VALUE ...]]

  send a command to the cue with the given NUMBER.

  NUMBER can be a string or a number, depending on the command.

  COMMAND can be one of:

    #{Qcmd.wrapped_text(Qcmd::Commands::CUE.sort.join(', '), :indent => '    ').join("\n")}

]
        end
      end

    end
  end
end
