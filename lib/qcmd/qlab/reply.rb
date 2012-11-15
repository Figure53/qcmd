module Qcmd
  module QLab
    class Reply < Struct.new(:osc_message)
      def json
        @json ||= JSON.parse(osc_message.to_a.first)
      end

      def address
        @address ||= json['address']
      end

      def data
        @data ||= json['data']
      end

      def is_cue_command?
        Qcmd::Commands.is_cue_command?(address)
      end

      def to_s
        "<Qcmd::Qlab::Reply address:'#{address}' data:#{data.inspect}>"
      end
    end
  end
end
