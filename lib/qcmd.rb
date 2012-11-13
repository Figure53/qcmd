require "qcmd/version"


module Qcmd
  # Your code goes here...
  autoload :Handler, 'qcmd/handler'
  autoload :Server, 'qcmd/server'
  autoload :CLI, 'qcmd/cli'
  autoload :Machine, 'qcmd/machine'
  autoload :Network, 'qcmd/network'

  autoload :VERSION, 'qcmd/version'

  class << self
    attr_accessor :log_level
    attr_accessor :debug_mode

    def verbose!
      self.log_level = :debug
    end

    def quiet!
      self.log_level = :warning
    end

    def debug?
      !!debug_mode
    end

    def debug message
      log(message) if log_level == :debug
    end

    def log *message
      puts(*message)
    end

    # always output
    def print *args
      log(*args)
    end
  end
end
