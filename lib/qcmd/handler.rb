module Qcmd
  class Handler
    def handle message, data
      case message
      when '/workspaces'
        puts "Workspaces:"

        data.each_with_index do |workspace, n|
          puts "#{ n + 1 }. #{ workspace['displayName'] }"
        end
      end
    end
  end
end
