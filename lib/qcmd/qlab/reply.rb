module Qcmd
  module QLab
    class Reply
      attr_accessor :address, :data
      def initialize osc_message
        @message = osc_message

        begin
          @json = JSON.parse @message.to_a.first
        rescue ParserError => ex
          Qcmd.print "FAILED TO PARSE QLAB RESPONSE"
          return
        end

        self.address = @json['address']
        self.data    = @json['data']
      end

      def is_cue_command?
        Qcmd::Commands.is_cue_command?(self.address)
      end

      def to_s
        "<Qcmd::Qlab::Reply address:'#{address}' data:#{self.data.inspect}>"
      end
    end
  end
end
