module Qcmd
  module QLab
    class Reply < Struct.new(:osc_message)
      def json
        @json ||= begin
                    Qcmd.debug "([Reply json] parsing osc_message #{ osc_message.to_a.inspect })"
                    JSON.parse(osc_message.to_a.first)
                  rescue => ex
                    Qcmd.debug "([Reply json] json parsing of osc_message failed on message #{ osc_message.to_a.inspect }. #{ ex.message })"
                    {}
                  end
      end

      def address
        @address ||= json['address']
      end

      def data
        @data ||= json['data']
      end

      def has_data?
        !data.nil?
      end

      def status
        @status ||= json['status']
      end

      def empty?
        false
      end

      def to_s
        "<Qcmd::Qlab::Reply address:'#{address}' status:'#{status}' data:#{data.inspect}>"
      end
    end
  end
end
