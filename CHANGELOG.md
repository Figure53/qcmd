### 0.1.8 to 0.1.9

* add help documentation for the "alias" command
* add "new" command to create new cues in QLab
* add "select" command to allow selection of a given cue (by number)
  * `select 2; go` would select and start the QLab workspace at the given cue
* allow IPv4 machine addresses

Internals:
* set default log level to `:info`
* separate machine connection and workspace loading
* simplify `send_workspace_command` method, clean up `send_command`
* add list of cue types for "new" command
* unify simple reply handling in CLI
* fix `-c "COMMAND"` command line option
* various small bug fixes

### 0.1.7 to 0.1.8

* create "alias" command to allow creation of commands from qcmd interactive interface
* add ".." (disconnect one level) command
* update location of qcmd settings and log files: `/Users/$USER/.qcmd/`
* replace CLI parser with aarongough/sexpistol
* use TCP connection and alwaysReply instead of UDP connection
* show current time and connection state in interactive mode
* persist command history across interactive qcmd sessions
* allow multiple commands separated with ";". For example,
  `cue 1 name; cue 2 name` would show the names of cues 1 and 2.
* better debug logging
