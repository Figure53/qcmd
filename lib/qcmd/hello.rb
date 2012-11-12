module Qcmd
  class Hello
    def self.speak p=nil
      puts(p || phrase)
    end

    def self.phrase
      'hello world'
    end
  end
end
