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

      def status
        @status ||= json['status']
      end

      def to_s
        "<Qcmd::Qlab::Reply address:'#{address}' data:#{data.inspect}>"
      end
    end
  end
end
