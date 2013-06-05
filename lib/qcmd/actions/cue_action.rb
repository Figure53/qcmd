module Qcmd
  class CueAction < BaseAction
    # cue commands should be in the form:
    #
    #   [$id_field, $identifier, $command[, $arguments]]
    #
    # where arguments are optional.

    def command
      code[2]
    end

    def osc_address
      "/#{ code[0] }/#{ code[1] }/#{ code[2] }"
    end

    def osc_arguments
      stringify code[3..-1]
    end

    # cue specific fields

    def id_field
      code[0]
    end

    def identifier
      code[1]
    end
  end
end

