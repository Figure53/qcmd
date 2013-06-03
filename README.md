# Qcmd

`qcmd` is intended to be a simple command line client for QLab utilizing
QLab 3's new OSC interface. `qcmd` should be useable from any machine on
the same local network as the QLab workspace you intend to work with.

This project is OS X only and has been tested against Ruby 1.8.7-p358 (OS X
10.8 default), Ruby 1.8.7 REE 2012.02, and Ruby 1.9.3-p327.

**This project should be considered experimental. DO NOT RUN SHOWS WITH
IT.**


## Installation

Before installing `qcmd`, you'll have to install the [Command Line Tools for
Xcode](https://developer.apple.com/downloads). They're free, but you'll need an
Apple ID to download them.

Once you've done that, you can install `qcmd` to your machine by running the
following command:

    $ sudo gem install qcmd

That should do ya.


## Starting the `qcmd` console.

Run the following command in a terminal window:

    $ qcmd

From there, you can connect to a machine, connect to a workspace, and then
send commands to cues and the workspace.

`qcmd` supports tab completion for commands in case you get stuck or are
wondering what you can do from the console. Type the beginning of a command and
hit tab to auto-complete the command, or hit it twice to see all possible
completions.

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

                       qcmd 0.1.9 (c) 2012 Figure 53, Baltimore, MD.

    Found 2 QLab machines

    1. my-mac-laptop
    2. f53imac

    Type `connect "MACHINE NAME"` or `connect IP_ADDRESS` to connect to a machine

    13:40
    > connect my-mac-laptop
    Connecting to machine: my-mac-laptop
    Connected to machine "my-mac-laptop"
    Connecting to workspace: Untitled Workspace 1
    Connected to "Untitled Workspace 1"
    Loaded 3 cues
    13:41 [my-mac-laptop] [Untitled Workspace 1]
    > cues

    ------------------------------- Cues: Main Cue List -------------------------------

       Number	   Id	        Name	    Type

            1	    1	         YOP	   Audio
            2	    2	  Not Armory	   Audio
            3	    3	        BUTT	   Audio


    13:41 [my-mac-laptop] [Untitled Workspace 1]
    > cue 3 name "Fix this name"
    ok
    13:41 [my-mac-laptop] [Untitled Workspace 1] [3 Fix this name]
    > start
    ok
    13:41 [my-mac-laptop] [Untitled Workspace 1] [3 Fix this name]
    > ..
    13:41 [my-mac-laptop] [Untitled Workspace 1]
    > hardStop
    ok
    13:41 [my-mac-laptop] [Untitled Workspace 1]
    > copy-name 3 2
    ok
    13:41 [my-mac-laptop] [Untitled Workspace 1] [2 Fix this name]
    > cues

    ------------------------------- Cues: Main Cue List -------------------------------

       Number	   Id	           Name	    Type

            1	    1	            YOP	   Audio
            2	    2	  Fix this name	   Audio
            3	    3	  Fix this name	   Audio


    13:41 [my-mac-laptop] [Untitled Workspace 1] [2 Fix this name]
    > alias smiley (cue $1 name ":) :) :) :) :) :)")
    Added alias for "smiley": (cue $1 name ":) :) :) :) :) :)")
    13:41 [my-mac-laptop] [Untitled Workspace 1] [2 Fix this name]
    > smiley 2
    ok
    13:41 [my-mac-laptop] [Untitled Workspace 1] [2 :) :) :) :) :) :)]
    > cues

    ------------------------------- Cues: Main Cue List -------------------------------

       Number	   Id	               Name	    Type

            1	    1	                YOP	   Audio
            2	    2	  :) :) :) :) :) :)	   Audio
            3	    3	      Fix this name	   Audio


    13:41 [my-mac-laptop] [Untitled Workspace 1] [2 :) :) :) :) :) :)]
    > exit
    exiting...


If you already know the machine you want to connect to, you can use the `-m`
option to connect immediately from the command line:

    $ qcmd -m "my mac laptop"
    Connecting to workspace: Untitled Workspace 1
    Connected to "Untitled Workspace 1"
    Loaded 1 cue
    10:15 [my mac laptop] [Untitled Workspace 1]
    >


If there's only one workspace available, `qcmd` will connect to the given machine
and then try to automatically connect to that workspace. If there's more than
one workspace, you can list it on the command line as well to connect immediately:

    $ qcmd -m "my mac laptop" -w "very special cues.cues"
    10:36 [my mac laptop] [very special cues.cues]
    >


Finally, if all you want `qcmd` to do is run a single command and exit, you can
use the `-c` option from the command line along with the `-m` and `-w` to make
sure `qcmd` knows where to send the message:

    $ qcmd -m "my mac laptop" -w "very special cues.cues" -c "cue 1 start"
    ok


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
