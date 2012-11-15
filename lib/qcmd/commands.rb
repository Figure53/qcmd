module Qcmd
  module Commands
    class << self
      def expects_reply? osc_message
        case osc_message.address
        when /connect/, /workspaces/, /cueLists/ # no args, always listen
          true
        when %r[cue/[^/]+/name] # listen if args not present
          if osc_message.has_arguments?
            false
          else
            true
          end
        else
          false
        end
      end

      def is_cue_command? address
        /cue/ =~ address && !(/Lists/ =~ address || /Cues/ =~ address)
      end

      def is_workspace_command? address
        /workspace/ =~ address && !(%r[cue/] =~ address || %r[cue_id/] =~ address)
      end
    end
  end
end
