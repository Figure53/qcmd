# require 'sxp'
require 'vendor/sexpistol/sexpistol'

module Qcmd
  module Parser
    class << self
      def parser
        @parser ||= Sexpistol.new
      end

      def parse(string)
        # make sure string is wrapped in parens to make the parser happy
        begin
          parser.parse_string "#{ string }"
        rescue => ex
          puts "parser FAILED WITH EXCEPTION: #{ ex.message }"
          raise
        end
      end

      def generate(sexp)
        parser.to_sexp(sexp)
      end
    end
  end
end
