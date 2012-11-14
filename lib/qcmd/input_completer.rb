require 'readline'

module Qcmd
  module InputCompleter
    ReservedWords = %w[
      connect exit workspaces disconnect cue
    ]

    CompletionProc = Proc.new {|input|
      # puts "input: #{ input }"
      # bind = Qcmd.context.binding

      matcher = /^#{Regexp.escape(input)}/
      commands = ReservedWords.grep(matcher)

      if Qcmd.connected?
        # haven't selected a workspace yet
        if !Qcmd.context.workspace
          workspace_names = Qcmd.context.machine.workspace_names.grep(matcher)
          workspace_names = workspace_names.map {|wsn|
            if / / =~ wsn
              %["#{ wsn }"]
            else
              wsn
            end
          }
          commands = commands + workspace_names
        else
          cue_numbers = Qcmd.context.workspace.cues.map(&:number)
          commands = commands + cue_numbers.grep(matcher)
        end
      else
        # haven't selected a machine yet
        commands = commands + Qcmd::Network.names.grep(matcher)
      end

      commands
    }
  end
end

if Readline.respond_to?("basic_word_break_characters=")
  Readline.basic_word_break_characters= " \t\n`><=;|&{("
end
Readline.completion_append_character = nil
Readline.completion_proc = Qcmd::InputCompleter::CompletionProc
