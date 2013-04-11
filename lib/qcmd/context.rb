module Qcmd
  class Context
    attr_accessor :machine, :workspace, :workspace_connected, :cue, :cue_connected

    def reset
      disconnect_machine
      disconnect_workspace
      disconnect_cue
    end

    def disconnect_machine
      self.machine = nil
    end

    def disconnect_workspace
      self.workspace = nil
      self.workspace_connected = false
    end

    def disconnect_cue
      self.cue = nil
      self.cue_connected = false
    end

    def machine_connected?
      !machine.nil?
    end

    def workspace_connected?
      !!workspace_connected
    end

    def cue_connected?
      !!cue_connected
    end

    def connection_state
      if !machine_connected?
        :none
      elsif !workspace_connected?
        :machine
      elsif !cue_connected?
        :workspace
      else
        :cue
      end
    end
  end
end
