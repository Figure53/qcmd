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

    def machine_connected?
      !machine.nil?
    end

    def workspace_connected?
      !!workspace_connected
    end

    def connection_state
      if !machine_connected?
        :none
      elsif !workspace_connected?
        :machine
      else
        :workspace
      end
    end

    def print_workspace_list
      Qcmd.print Qcmd.centered_text(" Workspaces ", '-')
      Qcmd.print

      machine.workspaces.each_with_index do |ws, n|
        Qcmd.print "#{ n + 1 }. #{ ws.name }#{ ws.passcode? ? ' [PROTECTED]' : ''}"
      end

      Qcmd.print
      Qcmd.print_wrapped('Type `use "WORKSPACE_NAME" PASSCODE` to load a workspace. Passcode is optional.')
      Qcmd.print
    end
  end
end
