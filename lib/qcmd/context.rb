module Qcmd
  class Context
    attr_accessor :machine, :workspace

    def reset
      self.machine = nil
      self.workspace = nil
    end
  end
end
