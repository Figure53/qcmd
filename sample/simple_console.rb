#!/usr/bin/env ruby

# ruby builtin
require 'readline'

require 'rubygems'

# use Qcmd's parser for type conversions and double quote recognizing
require 'qcmd'

# other gems
require 'osc-ruby'
require 'json'
require 'trollop'

# if there are args, there must be two:
#
#   send_address:send_port
#
# and
#
#   receive_port

VERSION_STRING =  "qcmd simple console #{ Qcmd::VERSION } (c) 2012 Figure 53, Baltimore, MD."

opts = Trollop::options do
  version VERSION_STRING
  opt :debug, "Show full debug output", :default => false
end

if opts[:debug]
  Qcmd.log_level = :debug
  Qcmd.debug_mode = true
end

Qcmd.print VERSION_STRING
Qcmd.print

# default qlab send to localhost:53000
send_address = 'localhost'
send_port = 53000

# default qlab receive port 53001. This is how QLab will send response
# messages.
receive_port = 53001

if ARGV.size > 0
  send_matcher = /([^:]+):(\d+)/
  recv_matcher = /(\d+)/

  if send_matcher =~ ARGV[0]
    send_address, send_port = $1, $2
  elsif recv_matcher =~ ARGV[0]
    receive_port = $1
  else
    Qcmd.print 'Send address must be an address in the form SERVER_ADDRESS:PORT'
    Qcmd.print
  end

  if ARGV[1]
    if recv_matcher =~ ARGV[1]
      receive_port = $1
    else
      Qcmd.print 'Send address must be a port number'
    end
  end
end

Qcmd.print %[connecting to server #{send_address}:#{send_port} with receiver at port #{receive_port}]

# how long to wait for responses from QLab. If you notice responses coming in
# out of order, you may need to increase this value.
REPLY_TIMEOUT = 1

# IO pipes to communicate between client / server process. In this case,
# the process talking to QLab is the client, which receives QLab's responses
# via the response_receiver.
response_receiver, response_writer = IO.pipe

class ClientReceiver
  attr_accessor :state, :channel

  def initialize channel, state
    @channel = channel
    @state   = state
  end

  def wait
    # wait for response until TIMEOUT seconds
    select = IO.select([channel], [], [], REPLY_TIMEOUT)
    if !select.nil?
      rs = select[0]

      # get readable channel
      if in_channel = rs[0]
        data = []

        # read everything until end of stream
        while line = in_channel.gets
          if line.strip != '<<EOS>>'
            data << line
          else
            break
          end
        end

        new_state = data.join
        Qcmd.debug "[response_receiver] new_state #{ new_state.inspect }"

        new_state_obj = Marshal::load(new_state)
        Qcmd.debug "[response_receiver] got state: #{ new_state_obj.inspect }"

        if new_state_obj[:state]
          self.state.merge! new_state_obj[:state]
        end

        if new_state_obj[:message]
          Qcmd.print new_state_obj[:message]
        end
      end
    else
      Qcmd.debug '[response_receiver] timed out'

      # select timed out, probably not going to get a response,
      # go back to command line mode
    end
  end
end

# fork readline process to allow server to communicate because if we use
# Thread.new, readline locks the WHOLE Ruby VM and the server can't start
pid = fork do
  # handle Ctrl-C quitting
  trap("INT") { exit }

  # close the IO channel that server process will be using
  response_writer.close

  # native OSC connection, outbound
  client = OSC::Client.new 'localhost', send_port

  command_state = {}
  receiver = ClientReceiver.new response_receiver, command_state

  # load list of workspaces
  client.send OSC::Message.new('/workspaces')
  receiver.wait

  # connect to frontmost workspace
  client.send OSC::Message.new('/connect')
  receiver.wait

  loop do
    # command prompt
    pre_prompt = nil
    prompt = "> "
    if command_state[:workspace_id]
      if command_state[:workspaces]
        name = command_state[:workspaces].fetch(command_state[:workspace_id], {}).fetch('displayName', nil)
      else
        name = command_state[:workspace_id]
      end

      if !name.nil?
        pre_prompt = "[#{ name }]"
      end
    end

    Qcmd.print(pre_prompt) if !pre_prompt.nil?
    command_string = Readline.readline(prompt, true)

    next if command_string.nil? || command_string.strip.size == 0

    # break command string up and properly typecast all given values
    args    = Qcmd::Parser.parse(command_string)
    address = args.shift

    # quit, q, and exit all quit
    exit if /^(q(uit)?|exit) ?$/i =~ address

    case address
    when 'state'
      Qcmd.print JSON.pretty_generate(command_state)
      next
    end

    # "sanitize" the given address
    if %r[^/] !~ address
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
    receiver.wait

  end
end

Qcmd.print "launched console with process id #{ pid }, use Ctrl-c or 'exit' to quit"

# close unused pipe
response_receiver.close

# native OSC connection, inbound
server = OSC::Server.new receive_port

response_handlers = [
  [
    %r{^/workspaces$},
    Proc.new { |data, message, response|
      workspaces = {}

      data.each {|ws|
        workspaces[ws['uniqueID']] = ws
      }

      data_out = Marshal::dump({
        :message => "#{workspaces.size} workspaces available: #{workspaces.values.map {|ws| ws['displayName']}.join(', ')}",
        :state => {:workspaces => workspaces}
      })

      Qcmd.debug "[/connect responder] sending marshalled object: #{ data_out.inspect }"

      response.puts data_out
    }
  ],
  [
    %r{^/workspace/.+/connect$},
    Proc.new { |data, message, response|
      if data == 'ok'
        data = Marshal::dump({:message => 'ok', :state => {:workspace_id => message['workspace_id']}})
      else
        data = Marshal::dump({:message => 'connection failed', :state => {:workspace_id => nil}})
      end

      Qcmd.debug "[/connect responder] sending marshalled object: #{ data.inspect }"
      response.puts data
    }
  ]
]

# server listens and forwards responses to the console process
server.add_method %r[/reply] do |osc_message|
  response = JSON.parse(osc_message.to_a.first)
  address  = response['address']
  data     = response['data']

  responded = false
  response_handlers.each do |(match, action)|
    if match =~ address
      action.call data, response, response_writer
      responded = true
    end
  end

  begin
    if !responded
      data = Marshal::dump({:message => JSON.pretty_generate(data)})
    end
  rescue JSON::GeneratorError
    data = Marshal::dump({:message => data.to_s})
  end

  if !responded
    Qcmd.debug  "[server] sending marshalled object: #{ data.inspect }"
    response_writer.puts data
  end

  # end of signal
  Qcmd.debug "[server] sending <<EOS>>"
  response_writer.puts '<<EOS>>'
end

# start blocking server
Thread.new do
  server.run
end

# chill until the command line process quits
begin
  Process.wait pid
rescue Interrupt
  # ignore
  exit
end
