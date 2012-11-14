module Qcmd
  class Machine < Struct.new(:name, :address, :port)
    def client_arguments
      [address, port]
    end

    def client_string
      "#{ address }:#{ port }"
    end

    def workspaces= val
      @workspaces = val
    end

    def workspaces
      @workspaces || []
    end

    def workspace_names
      @workspaces.map(&:name) || []
    end

    def find_workspace name
      @workspaces.find {|ws| ws.name == name}
    end
  end
end
