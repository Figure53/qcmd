# Qcmd

`qcmd` is intended to be a simple command line client for QLab utilizing
QLab 3's new OSC interface. `qcmd` should be useable from any machine on
the same local network as the QLab workspace you intend to work with.

This project is OS X only and has been tested against Ruby 1.8.7-p358 (OS X
10.8 default), Ruby 1.8.7 REE 2012.02, and Ruby 1.9.3-p327.

**This project should be considered experimental. DO NOT RUN SHOWS WITH
IT.**


## Installation

Before installing qcmd, you'll have to install the [Command Line Tools for
Xcode](https://developer.apple.com/downloads). They're free, but you'll need an
Apple ID to download them.

Once you've done that, you can install qcmd to your machine by running the
following command:

    $ sudo gem install qcmd

That should do ya.


## Starting the `qcmd` console.

Run the following command in a terminal window:

    $ qcmd

From there, you can connect to a machine, connect to a workspace, and then
send commands to cues and the workspace.

`qcmd` supports tab completion for commands in case you get stuck or are
wondering what you can do from the console.

Run `qcmd` with the -v option to get full debugging output. Use the main
project repository (https://github.com/Figure53/qcmd) to report any issues.

An example session might look like this:

    $ qcmd
                         .::::    .::                .::
                       .::    .:: .::                .::
                     .::       .::.::         .::    .::
                     .::       .::.::       .::  .:: .:: .::
                     .::       .::.::      .::   .:: .::   .::
                       .:: .: .:: .::      .::   .:: .::   .::
                         .:: ::   .::::::::  .:: .:::.:: .::
                              .:

                   qcmd 0.1.0 (c) 2012 Figure 53, Baltimore, MD.

    Found 2 QLab machines

    1. adam-retina
    2. f53zwimac

    type `connect MACHINE` to connect to a machine

    > connect adam-retina
    connecting to machine: adam-retina
    -------------------------------- Workspaces --------------------------------

    1. Untitled Workspace

    Type `use "WORKSPACE_NAME" PASSCODE` to load a workspace. Only enter a
    passcode if your workspace uses one

    adam-retina> use "Untitled Workspace"
    connecting to workspace: Untitled Workspace
    connected to workspace
    loaded 2 cues
    adam-retina:Untitled Workspace> cues

    ----------------------------------- Cues -----------------------------------

      Number          Id      Name    Type

           1           2      Nope    Wait
           2           3      Nipe   Audio


    adam-retina:Untitled Workspace> cue 2 start
    adam-retina:Untitled Workspace> cue 2 isRunning
    true
    adam-retina:Untitled Workspace> workspace runningCues

    ------------------------------- Running Cues -------------------------------

     Number  Id      Name     Type

          2   3      Nipe    Audio


    adam-retina:Untitled Workspace> cue 2
    1                       2                       actionElapsed
    allowsEditingDuration   armed                   basics
    children                colorName               connect
    continueMode            cue                     cueLists
    cueTargetId             cueTargetNumber         disconnect
    duration                exit                    flagged
    hasCueTargets           hasFileTargets          isBroken
    isLoaded                isPaused                isRunning
    load                    loadAt                  name
    notes                   number                  panic
    pause                   percentActionElapsed    percentPostWaitElapsed
    percentPreWaitElapsed   postWait                postWaitElapsed
    preview                 preWait                 preWaitElapsed
    reset                   resume                  runningCues
    runningOrPausedCues     selectedCues            stop
    thump                   type                    uniqueID
    workspace               workspaces
    adam-retina:Untitled Workspace> cue 2 pause
    adam-retina:Untitled Workspace> cue 2 isRunning
    false
    adam-retina:Untitled Workspace> cue 2 percentActionElapsed
    0.109189204871655
    adam-retina:Untitled Workspace> disconnect

    Found 2 QLab machines

    1. adam-retina
    2. f53zwimac

    type `connect MACHINE` to connect to a machine

    > exit
    exiting...


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
