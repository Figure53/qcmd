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
      attr_accessor :data

      def initialize options={}
        self.data = options
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
    end
  end
end
