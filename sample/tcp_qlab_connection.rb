require 'qcmd'

require 'rubygems'
require 'json'

# try it out

qlab = OSC::TCPClient.new 'localhost', 53000

def receive(rcv)
  if rcv
    rcv.each do |osc_message|
      begin
        response = JSON.parse(osc_message.to_a.first)

        address  = response['address']
        data     = response['data']
        status   = response['status']

        puts address

        if status
          puts "status -> #{ status }"
        end

        if data
          puts JSON.pretty_generate(data)
        end
      rescue => ex
        puts "parsing response failed: #{ ex.message }"
      end
    end
  else
    puts 'no response...'
  end
end

msg  = OSC::Message.new '/workspaces'
qlab.send(msg) do |response|
  receive(response)
end

# don't always expect a reply
msg = OSC::Message.new '/alwaysReply', 0
qlab.send(msg) do |response|
  receive(response)
end

# non-responsive command
msg  = OSC::Message.new '/workspace/65E9D86D-87DD-4CB1-A659-6584BAE57AB2/go'
qlab.send(msg) do |response|
  receive(response)
end

# always expect a reply
msg = OSC::Message.new '/alwaysReply', 1
qlab.send(msg) do |response|
  receive(response)
end

# non-responsive command is now a responsive command
msg  = OSC::Message.new '/workspace/65E9D86D-87DD-4CB1-A659-6584BAE57AB2/go'
qlab.send(msg) do |response|
  receive(response)
end


