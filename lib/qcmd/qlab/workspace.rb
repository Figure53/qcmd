module Qcmd
  module QLab
    #
    #   "uniqueID": string,
    #   "displayName": string
    #   "hasPasscode": number
    #
    class Workspace
      attr_accessor :data, :passcode, :cue_lists

      def initialize options={}
        self.data = options
      end

      def name
        data['displayName']
      end

      def passcode?
        !!data['hasPasscode']
      end

      def id
        data['uniqueID']
      end

      # all cues in this workspace
      def cues
        cue_lists.map do |cl|
          load_cues(cl, [])
        end.flatten.compact
      end

      private

      def load_cues parent_cue, cues
        parent_cue.cues.each {|child_cue|
          cues << child_cue
          load_cues child_cue, cues
        }

        cues
      end
    end
  end
end
