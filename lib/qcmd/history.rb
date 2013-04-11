module Qcmd
  class History
    class << self
      attr_accessor :commands

      def load
        if File.exists?(Qcmd::Configuration.history_file)
          lines = File.new(Qcmd::Configuration.history_file, 'r').readlines
        else
          lines = []
        end

        if lines
          lines.reverse[0..100].reverse.each {|hist|
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
