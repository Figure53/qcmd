require "qcmd/version"

module Qcmd
  # Your code goes here...
  autoload :Hello, 'qcmd/hello'

  class << self
    def hello
      puts 'hello world'
    end
  end
end
