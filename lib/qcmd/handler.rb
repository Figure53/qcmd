module Qcmd
  class Handler
    def handle message, data
      case message
      when '/workspaces'
        Qcmd.print "Workspaces:"

        data.each_with_index do |workspace, n|
          Qcmd.print "#{ n + 1 }. #{ workspace['displayName'] }"
        end
      end
    end
  end
end
