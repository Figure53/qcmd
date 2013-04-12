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

    GROUP_CUE = %w(
      playbackPositionId
    )

    AUDIO_CUE = %w(
      doFade
      doPitchShift
      endTime
      infiniteLoop
      level
      patch
      playCount
      rate
      sliderLevel
      sliderLevels
      startTime
    )

    FADE_CUE = %w(
      level
      sliderLevel
      sliderLevels
    )

    MIC_CUE = %w(
      level
      sliderLevel
      sliderLevels
    )

    VIDEO_CUE = %w(
      cueSize
      doEffect
      doFade
      doPitchShift
      effect
      effectSet
      endTime
      fullScreen
      infiniteLoop
      layer
      level
      opacity
      patch
      playCount
      preserveAspectRatio
      quaternion
      rate
      scaleX
      scaleY
      sliderLevel
      sliderLevels
      startTime
      surfaceID
      surfaceList
      surfaceSize
      translationX
      translationY
    )

    ALL_CUES = (CUE + GROUP_CUE + AUDIO_CUE + FADE_CUE + MIC_CUE + VIDEO_CUE).uniq.sort

    module Help
      class << self

        def print_all_commands
          Qcmd.print %[
#{Qcmd.centered_text(' Available Commands ', '-')}




exit

  Close qcmd.


connect MACHINE_ID

  Connect to the machine with id MACHINE_ID. This can either be the name of the
  machine shown in the listing or its number on the list. Once a machine is
  connected its name will appear above the prompt.



disconnect

  Disconnect from the current machine and workspace.


..

  Disconnect cue if one is connected. If not, disconnect the current workspace.
  If one is not connected, disconnect from the machine.


use WORKSPACE_NAME [PASSCODE]

  Connect to the workspace with name WORKSPACE_NAME given as a double quoted
  string using passcode PASSCODE. A passcode is only required if the workspace
  has one enabled. Once a workspace is connected its name will appear above the
  prompt.


workspaces

  Show a list of the available workspaces for the currently connected machine.


workspace COMMAND [VALUE]

  Pass the given COMMAND to the connected workspace. The following commands will
  act on a workspace:

    #{Qcmd.wrapped_text(Qcmd::Commands::WORKSPACE.sort.join(', '), :indent => '    ').join("\n")}

  * Pro Tip: once you are connected to a workspace, you can just use COMMAND
  and leave off "workspace" to quickly send the given COMMAND to the connected
  workspace.


cue NUMBER COMMAND [VALUE [ANOTHER_VALUE ...]]

  or

cue_id ID COMMAND [VALUE [ANOTHER_VALUE ...]]

  Send a command to the cue with the given NUMBER or ID depending on the way
  you are addressing the cue.

  NUMBER can be a double quoted string or a number, depending on the command.

  COMMAND can be one of:

    #{Qcmd.wrapped_text(Qcmd::Commands::CUE.sort.join(', '), :indent => '    ').join("\n")}

  Specific types of cues may have different cues available. Here's the commands
  available for different types of cues:

  Group Cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::GROUP_CUE.sort.join(', '), :indent => '    ').join("\n")}

  Audio Cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::AUDIO_CUE.sort.join(', '), :indent => '    ').join("\n")}

  Fade Cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::FADE_CUE.sort.join(', '), :indent => '    ').join("\n")}

  Mic Cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::MIC_CUE.sort.join(', '), :indent => '    ').join("\n")}

  Video Cue:

    #{Qcmd.wrapped_text(Qcmd::Commands::VIDEO_CUE.sort.join(', '), :indent => '    ').join("\n")}

  Once a command has been sent to an existing cue, subsequent cue commands will
  be sent to the same cue with needing to repeat the leading "cue NUMBER". Once
  a cue is connected its name will appear above the prompt.

---------------------

For example:

    11:03
    > connect qlab-mini
    connecting to machine: qlab-mini
    connected to qlab-mini
    ------------------------------------ Workspaces -------------------------------------

    1. my workspace.cues

    Type `use "WORKSPACE_NAME" PASSCODE` to load a workspace. Passcode is
    optional.

    11:03 [qlab-mini]
    > use "my workspace.cues"
    connecting to workspace: my workspace.cues
    connected to workspace
    loaded 13 cues
    11:04 [qlab-mini] [my workspace.cues]
    > cue 2 start
    ok
    11:04 [qlab-mini] [my workspace.cues] [AFTER THE LAST SCENE]
    > rate 0.2
    ok
    11:04 [qlab-mini] [my workspace.cues] [AFTER THE LAST SCENE]
    > stop
    ok
    11:04 [qlab-mini] [my workspace.cues] [AFTER THE LAST SCENE]
    > ..
    11:04 [qlab-mini] [my workspace.cues]
    > disconnect
    11:04
    >


]
        end
      end

    end
  end
end
