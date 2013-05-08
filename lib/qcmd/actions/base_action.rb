module Qcmd
  class BaseAction
    attr_reader :code

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

      @code = parse(expression)
    end

    def evaluate
      if code.size == 0
        nil
      else
        @code = code.map do |token|
          if token.is_a?(Action)
            Qcmd.debug "[Action evaluate] evaluating nested action: #{ token.code.inspect }"
            token.evaluate
          else
            token
          end
        end

        Qcmd.debug "[Action evaluate] evaluating code: #{ code.inspect }"

        send_message
      end
    end

    def parse(expression)
      # unwrap nested arrays
      if expression.size == 1 && expression[0].is_a?(Array)
        expression = expression[0]
      end

      expression.map do |token|
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

    def send_message
      responses = []

      Qcmd.debug "[Action send_message] send #{ osc_message.encode }"
      Qcmd.context.qlab.send(osc_message) do |response|
        # puts "response to: #{ osc_message.inspect }"
        # puts response.inspect

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
