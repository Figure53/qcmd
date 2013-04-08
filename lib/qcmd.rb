require 'socket'
require 'osc-ruby'

require 'qcmd/version'

require 'qcmd/plaintext'
require 'qcmd/commands'
require 'qcmd/input_completer'

require 'qcmd/core_ext/array'
require 'qcmd/core_ext/osc/message'
require 'qcmd/core_ext/osc/stopping_server'

module Qcmd
  autoload :Configuration, 'qcmd/configuration'
  autoload :History, 'qcmd/history'
  autoload :Handler, 'qcmd/handler'
  autoload :Server, 'qcmd/server'
  autoload :Context, 'qcmd/context'
  autoload :Parser, 'qcmd/parser'
  autoload :CLI, 'qcmd/cli'
  autoload :Machine, 'qcmd/machine'
  autoload :Network, 'qcmd/network'
  autoload :QLab, 'qcmd/qlab'
  autoload :VERSION, 'qcmd/version'

  # on launch

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

    def silent!
      self.log_level = :none
    end

    def silent?
      self.log_level == :none
    end

    def quiet?
      self.log_level == :warning
    end

    def while_quiet
      previous_level = self.log_level
      self.log_level = :warning
      yield
      self.log_level = previous_level
    end

    def debug?
      !!debug_mode
    end

    def debug message
      # always write to log
      Qcmd::Configuration.log.puts message

      log(message) if log_level == :debug
    end

    def connected?
      !!context && !!context.machine && !context.machine.nil?
    end
  end
end
