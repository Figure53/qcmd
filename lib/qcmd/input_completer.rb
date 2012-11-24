require 'readline'

module Qcmd
  module InputCompleter
    # the commands listed here should represent every possible legal command
    ReservedWords = %w[
      connect exit quit workspace workspaces disconnect help
    ]

    ReservedWorkspaceWords = Qcmd::Commands::ALL_WORKSPACE_COMMANDS

    ReservedCueWords = Qcmd::Commands::ALL_CUE_COMMANDS

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
          workspace_names = quote_if_necessary workspace_names
          commands = commands + workspace_names
        end
      else
        # haven't selected a machine yet
        machine_names = Qcmd::Network.names
        quoted_names = machine_names.map {|mn| %["#{mn}"]}
        names = (quoted_names + machine_names).grep(matcher)
        names = quote_if_necessary(names)
        # unquote
        commands = commands + names
      end

      commands
    }

    class << self
      # if the name of a thing has a space in it, it must be surrounded by double
      # quotes to be properly handled by the parser. so before we pass back
      # unquoted space-containing results, we must quote them.
      def quote_if_necessary names
        names.map do |name|
          if / / =~ name && /"/ !~ name
            # if name has a space and is not already quoted
            %["#{ name }"]
          else
            name
          end
        end
      end
    end
  end
end

if Readline.respond_to?("basic_word_break_characters=")
  Readline.basic_word_break_characters= " \t\n`><=;|&{("
end
Readline.completion_append_character = nil
Readline.completion_case_fold = true
Readline.completion_proc = Qcmd::InputCompleter::CompletionProc
