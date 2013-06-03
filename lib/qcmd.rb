# communicate!
require 'socket'
require 'osc-ruby'

# data from QLab
require 'json'

require 'qcmd/version'
require 'qcmd/plaintext'
require 'qcmd/commands'
require 'qcmd/input_completer'
require 'qcmd/core_ext/array'
require 'qcmd/core_ext/string'
require 'qcmd/core_ext/osc/message'
require 'qcmd/core_ext/osc/tcp_client'

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
  autoload :Aliases, 'qcmd/aliases'

  autoload :Action, 'qcmd/action'
  autoload :CueAction, 'qcmd/action'

  # on launch

  class << self
    include Qcmd::Plaintext

    attr_accessor :debug_mode
    attr_accessor :context

    LEVELS = %w(debug info warning error none)

    def log_level
      @log_level ||= :info
    end

    def log_level=(value)
      if LEVELS.include?(value.to_s)
        @log_level = value
      else
        raise "Invalid log_level value: #{ value.to_s }"
      end
    end

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
      Qcmd::Configuration.log.puts "[%s] %s" % [Time.now.strftime('%T'), message]

      # forward message to log
      log(:debug, message)
    end

    def log_level_acheived? level
      LEVELS.index(level.to_s) >= LEVELS.index(log_level.to_s)
    end

    def connected?
      !!context && !!context.machine && !context.machine.nil?
    end
  end
end
