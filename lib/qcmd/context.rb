module Qcmd
  class Context
    attr_accessor :machine, :workspace, :workspace_connected

    def reset
      disconnect_machine
      disconnect_workspace
    end

    def disconnect_machine
      self.machine = nil
    end

    def disconnect_workspace
      self.workspace = nil
      self.workspace_connected = false
    end

    def workspace_connected?
      !!workspace_connected
    end
  end
end
