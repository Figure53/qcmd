require 'qcmd/version'
require 'qcmd/input_completer'

require 'qcmd/core_ext/array'
require 'qcmd/core_ext/osc/message'

module Qcmd
  # Your code goes here...
  autoload :Handler, 'qcmd/handler'
  autoload :Server, 'qcmd/server'
  autoload :Context, 'qcmd/context'
  autoload :Parser, 'qcmd/parser'
  autoload :CLI, 'qcmd/cli'
  autoload :Machine, 'qcmd/machine'
  autoload :Network, 'qcmd/network'
  autoload :QLab, 'qcmd/qlab'
  autoload :Plaintext, 'qcmd/plaintext'
  autoload :Commands, 'qcmd/commands'
  autoload :VERSION, 'qcmd/version'

  class << self
    include Qcmd::Plaintext

    attr_accessor :log_level
    attr_accessor :debug_mode
    attr_accessor :context

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

    def connected?
      !!context && !!context.machine && !context.machine.nil?
    end
  end
end
