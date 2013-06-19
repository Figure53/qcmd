module Qcmd
  class Context
    attr_accessor :machine, :workspace, :workspace_connected, :cue, :cue_connected, :qlab

    def reset
      disconnect_machine
      disconnect_workspace
      disconnect_cue
    end

    def disconnect_machine
      self.qlab.close unless self.qlab.nil?
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

    def connect_to_qlab handler=nil
      # get an open connection with the default handler
      handler ||= Qcmd::Handler
      self.qlab = OSC::TCP::Client.new(machine.address, machine.port, handler)
    end
  end
end
