module Qcmd
  module QLab
    #
    #   "uniqueID": string,
    #   "displayName": string
    #   "hasPasscode": number
    #
    class Workspace
      attr_accessor :data, :passcode, :cue_lists, :cues

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
    end
  end
end
