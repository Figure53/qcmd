module Qcmd
  class History
    class << self
      attr_accessor :commands

      def load
        lines = File.new(Qcmd::Configuration.history_file, 'r').readlines

        if lines
          if lines.length > 100
            first = -100
          else
            first = -(lines.length)
          end

          lines[first..-1].reverse.each {|hist|
            Readline::HISTORY.push(hist)
          }
        end
      end


      def push command
        Qcmd::Configuration.history.puts command
      end
    end
  end
end
