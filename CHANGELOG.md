### 0.1.9 to 0.1.16

* replace command parser with updated version of [Sexpistol](https://github.com/aarongough/sexpistol).
* add "sleep" command. 1f047b45eb33e0d65563fae0eb1eb73e4fb61ee9
* add log related commands (`log-silent`, `log-noisy`, `log-debug`, `log-info`,
  and `echo`) for use in alias commands. 16b10d1c824c31a32716e5bbeb08adf4858ba4c6
* multiple commands can be given when launching qcmd with the -c option 16b10d1c824c31a32716e5bbeb08adf4858ba4c6
* add ++, --, \*\*, and // command modifiers df4eca08865225927c32fe73d1dd5038807209a6
* add a TCP based OSC server to support qcmd-proxy 436f7384ba0fee9dc2bbf25df19e7b78c4b60fb2
* create qcmd-proxy to allow for easier debugging of OSC apps that want to talk to QLab

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
