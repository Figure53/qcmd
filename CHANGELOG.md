### 0.1.8 -> 0.1.9

* add "alias" command to help
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


