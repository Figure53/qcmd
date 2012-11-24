#!/usr/bin/env ruby

# ruby builtin
require 'readline'

require 'rubygems'

# use Qcmd's parser for type conversions and double quote recognizing
require 'qcmd/parser'

# other gems
require 'osc-ruby'
require 'json'

# handle Ctrl-C quitting
trap("INT") { exit }

# if there are args, there must be two:
#
#   send_address:send_port
#
# and
#
#   receive_port

# default qlab send port 53000
send_address = 'localhost'
send_port    = 53000

# default qlab receive port 53001
receive_port = 53001

if ARGV.size > 0
  send_matcher = /([^:]+):(\d+)/
  recv_matcher = /(\d+)/

  if send_matcher =~ ARGV[0]
    send_address, send_port = $1, $2
  elsif recv_matcher =~ ARGV[0]
    receive_port = $1
  else
    puts 'send address must be an address in the form SERVER_ADDRESS:PORT'
  end

  if ARGV[1]
    if recv_matcher =~ ARGV[1]
      receive_port = $1
    else
      puts 'send address must be a port number'
    end
  end
end

puts %[connecting to server #{send_address}:#{send_port} with receiver at port #{receive_port}]

# how long to wait for responses from QLab. If you notice responses coming in
# out of order, you may need to increase this value.
REPLY_TIMEOUT = 1

# open IO pipes to communicate between client / server process
response_receiver, writer = IO.pipe

# fork readline process to allow server to communicate because if we use
# Thread.new, readline locks the WHOLE Ruby VM and the server can't start
pid = fork do
  # close the IO channel that server process will be using
  writer.close

  # native OSC connection, outbound
  client = OSC::Client.new 'localhost', send_port

  loop do
    command_string = Readline.readline('> ', true)
    next if command_string.nil? || command_string.strip.size == 0

    # break command string up and properly typecast all given values
    args    = Qcmd::Parser.parse(command_string)
    address = args.shift

    # quit, q, and exit all quit
    exit if /^(q(uit)?|exit)/i =~ address

    # "sanitize" the given address
    if %r[^/] != address
      if address == '>'
        # pasted previous command line entry
        address = args.shift
      else
        # add lazy slash
        address = "/#{ address }"
      end
    end

    message = OSC::Message.new(address, *args)
    client.send message

    # wait for response until TIMEOUT seconds
    select = IO.select([response_receiver], [], [], REPLY_TIMEOUT)
    if !select.nil?
      rs = select[0]

      # get readable channel
      if in_channel = rs[0]
        # read everything until end of stream
        while line = in_channel.gets
          if line.strip != '<<EOS>>'
            puts line
          else
            break
          end
        end
      end
    else
      # select timed out, probably not going to get a response,
      # go back to command line mode
    end
  end
end

puts "launched console with process id #{ pid }, use Ctrl-c or 'exit' to quit"

# close unused pipe
response_receiver.close

# native OSC connection, inbound
server = OSC::Server.new receive_port

# server listens and forwards responses to the forked process
server.add_method %r[/reply] do |osc_message|
  data = JSON.parse(osc_message.to_a.first)

  begin
    writer.puts JSON.pretty_generate(data)
  rescue JSON::GeneratorError
    writer.puts data.to_s
  end

  # end of signal
  writer.puts '<<EOS>>'
end

# start blocking server
Thread.new do
  server.run
end

# chill until the command line process quits
Process.wait pid
