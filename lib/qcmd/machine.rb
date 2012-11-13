module Qcmd
  class Machine < Struct.new(:name, :address, :port)
    def client_arguments
      [address, port]
    end

    def client_string
      "#{ address }:#{ port }"
    end
  end
end
