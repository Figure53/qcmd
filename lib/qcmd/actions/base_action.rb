module Qcmd
  class BaseAction
    attr_reader :code
    attr_accessor :modification

    # initialize and evaluate in one shot
    def self.evaluate action_input
      is_cue_action = false

      if action_input.is_a?(String)
        is_cue_action = %w(cue cue_id).include?(action_input.split.first)
      else
        is_cue_action = ['cue', 'cue_id', :cue, :cue_id].include?(action_input.first)
      end

      if is_cue_action
        CueAction.new(action_input).evaluate
      else
        Action.new(action_input).evaluate
      end
    end

    def initialize(expression)
      if expression.is_a?(String)
        expression = Qcmd::Parser.parse(expression)
      end

      parse(expression)
    end

    def evaluate
      if code.size == 0
        nil
      else
        @code = code.map do |token|
          if token.is_a?(BaseAction)
            Qcmd.debug "[Action evaluate] evaluating nested action: #{ token.code.inspect }"
            token.evaluate
          else
            token
          end
        end

        Qcmd.debug "[Action evaluate] evaluating code: #{ code.inspect }"

        response = send_message
        if modification
          modification.call(response)
        else
          response
        end
      end
    end

    # convert nested arrays into new actions
    def parse(expression)
      if expression.size == 1 && expression[0].is_a?(Array)
        expression = expression[0]
      end

      @code = expression.map do |token|
        if token.is_a?(Array)
          if [:cue, :cue_id].include?(token.first)
            Qcmd.debug "nested cue action detected in #{ expression.inspect }"
            CueAction.new(token)
          else
            Action.new(token)
          end
        else
          token
        end
      end.tap {|exp|
        Qcmd.debug "[Action parse] returning: #{ exp.inspect }"
      }

      # if there's a trailing modifier command, replace it with an action that will
      # return a value that can be modified.
      if tm = trailing_modifier
        Qcmd.debug "[Action parse] found trailing modifier: #{ tm.inspect }"

        mod_type = tm[0]
        mod_value = tm[2].to_f

        # clone this action without the final arg
        new_action = self.class.new(@code[0, @code.size - 1])

        Qcmd.debug "[Action parse] creating modification proc: value.send(:#{ mod_type }, #{ mod_value })"
        new_action.modification = Proc.new {|value|
          Qcmd.debug "[Action parse] executing modification proc: #{ value }.send(:#{ mod_type }, #{ mod_value })"
          if value.respond_to?(mod_type)
            value.send mod_type, mod_value
          else
            Qcmd.log :warning, "The command `#{ new_action.code.join(' ') }` returned a value of type #{ value.class.to_s } which does not understand the #{ mod_type } modifier."
            value
          end
        }

        code[code.size - 1] = new_action
      end
    end

    # the default command builder
    def osc_message
      OSC::Message.new osc_address.to_s, *osc_arguments
    end

    def osc_address
      # prefix w/ slash if necessary
      if %r[^/] !~ code[0].to_s
        "/#{ code[0] }"
      else
        code[0]
      end
    end

    def osc_address=(value)
      code[0] = value
    end

    def osc_arguments
      stringify code[1..-1]
    end

    # the raw command
    def command
      code[0]
    end

    private

    # is the last argument to the osc command a modifier?
    # returns nil or [modifier, matcher, matched_value]
    def trailing_modifier
      if osc_arguments && !osc_arguments.last.is_a?(BaseAction)
        modifier = modifiers.find {|(_, matcher)|
          matcher =~ osc_arguments.last.to_s
        }

        if modifier
          modifier + [$1]
        else
          nil
        end
      else
        nil
      end
    end

    def number_matcher
      # matches 1.9, .9, or 1
      "(?: [0-9]+ \. [0-9]+ | \. [0-9]+ | [0-9]+ )"
    end

    def modifiers
      [
        [:+, /^\+\+(#{ number_matcher })/x],
        [:-, /--(#{ number_matcher })/x],
        [:/, /\/\/(#{ number_matcher })/x],
        [:*, /\*\*(#{ number_matcher })/x]
      ]
    end

    def modifier_matchers
      modifiers.map(&:last)
    end

    def send_message
      responses = []

      Qcmd.debug "[Action send_message] send #{ osc_message.encode }"
      Qcmd.context.qlab.send(osc_message) do |response|
        responses << QLab::Reply.new(response)
      end

      if responses.size == 1
        q_reply = responses[0]
        Qcmd.debug "[Action send_message] got one response: #{q_reply.inspect}"

        if q_reply.has_data?
          q_reply.data
        else
          q_reply
        end
      else
        responses
      end
    end

    def stringify args
      if args.nil?
        nil
      else
        args.map {|arg|
          if arg.is_a?(Symbol)
            arg.to_s
          else
            arg
          end
        }
      end
    end
  end
end
