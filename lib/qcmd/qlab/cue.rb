module Qcmd
  module QLab
    #  All return an array of cue dictionaries:
    #
    #  [
    #      {
    #          "uniqueID": string,
    #          "number": string
    #          "name": string
    #          "type": string
    #          "colorName": string
    #          "flagged": number
    #          "armed": number
    #      }
    #  ]
    #  If the cue is a group, the dictionary will include an array of cue dictionaries for all children in the group:
    #
    #  [
    #      {
    #          "uniqueID": string,
    #          "number": string
    #          "name": string
    #          "type": string
    #          "colorName": string
    #          "flagged": number
    #          "armed": number
    #          "cues": [ { }, { }, { } ]
    #      }
    #  ]
    #
    #  [{\"number\":\"\",
    #    \"uniqueID\":\"1\",
    #    \"cues\":[{\"number\":\"1\",
    #    \"uniqueID\":\"2\",
    #    \"flagged\":false,
    #    \"type\":\"Wait\",
    #    \"colorName\":\"none\",
    #    \"name\":\"boom\",
    #    \"armed\":true}],
    #    \"flagged\":false,
    #    \"type\":\"Group\",
    #    \"colorName\":\"none\",
    #    \"name\":\"Main Cue List\",
    #    \"armed\":true}]

    class Cue
      TYPES = %w(audio mic video camera fade osc midi midi file timecode group
                 start stop pause load reset devamp goto target arm disarm wait
                 memo script cuelist)

      attr_accessor :data

      def initialize options={}
        self.data = options
      end

      def sync
        Qcmd.debug "[Cue sync] synchronizing cue with id #{ self.id }"

        # reload cue properties from QLab
        fields = %w(uniqueID number name type colorName flagged armed cues)
        self.data = Qcmd::CueAction.evaluate("cue_id #{ self.id } valuesForKeys #{ JSON.dump(fields).inspect }")
      end

      def id
        data['uniqueID']
      end

      def name
        data['name']
      end

      def number
        data['number']
      end

      def type
        data['type']
      end

      def cues
        if data['cues'].nil?
          []
        else
          data['cues'].map {|c| Qcmd::QLab::Cue.new(c)}
        end
      end

      def has_cues?
        cues.size > 0
      end
    end
  end
end
