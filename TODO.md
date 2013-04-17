### copyable fields

* sliderLevels
* fade shape
* action
* preWait
* postWait
* AU status?
* geometry
* full matrix


### aliases and composable actions

`alias n (cue $1 name $2)` creates a new command, "n" that can be called just
like any built in command.  `n 20 "Basic Intro"` expands into `cue 20 name "Basic Intro"`.

All actions should have a return value, then we can nest commands to create new
actions:

`alias copy-name (cue $2 name (cue $1 name))`

The **$** argument operator can be included in double quoted strings to act as
a simple templating tool. For example: `alias act-scene (cue $1 name "Act $2: Scene $3")`
could be used to give cues a specifc name with some plugged-in values. Now using
`act-scene 20 1 2` would give cue number 20 the name "Act 1: Scene 2".

Because custom actions expand into qcmd's normal actions, wildcards should work
fine. `act-scene 20.* 1 2` would change the name of every cue whose number
starts with "20." to "Act 1: Scene 2".

