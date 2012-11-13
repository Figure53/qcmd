require "qcmd/version"


module Qcmd
  # Your code goes here...
  autoload :Handler, 'qcmd/handler'
  autoload :Server, 'qcmd/server'
  autoload :CLI, 'qcmd/cli'

  class << self
    # class methods on Qcmd go here
    def debug *args
      puts(*args)
    end
  end
end
