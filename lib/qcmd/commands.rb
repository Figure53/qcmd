module Qcmd
  class Command < Struct.new(:name, :response)
  end

  module Commands

    # name, response

    class << self
      def expects_reply? osc_message
        # Qcmd.debug "(expects_reply? #{ osc_message.address } " +
        #            "#{ osc_message.has_arguments? ? 'with' : 'without' } arguments)"

        case osc_message.address
        when /workspaces/, /cueLists/ # no args, always listen
          true
        when %r[cue/[^/]+/name] # listen if args not present
          if osc_message.has_arguments?
            false
          else
            true
          end
        when %r[workspace/[^/]+/connect] # listen if args present
          if osc_message.has_arguments?
            true
          else
            false
          end
        else
          false
        end
      end
    end
  end
end
