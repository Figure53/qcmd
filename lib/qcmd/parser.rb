module Qcmd
  module Parser
    class << self
      def parser
        @parser ||= Sexpistol.new
      end

      def parse( string )
        parser.parse_string string
      end
    end
  end
end
