require 'rubygems'
require 'qcmd'
require 'json'

puts "setting up server"

# server must come first
server = OSC::TCP::Server.new 52000
server.add_method(/.*/) do |message|
  ip_address = message.ip_address.sub(/\.\.\./, '')
  ts = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  types = message.to_a.map(&:class).map(&:to_s).join(', ')
  args  = message.to_a

  puts "[#{ts}] #{message.ip_address}:#{message.ip_port} -- #{message.address} -- [#{ types }] -- #{ args.inspect }"

  message.responder.send OSC::Message.new("/hello-to-you-too")
end

puts "starting server"
thread = Thread.new do
  server.run
end

class MyClientHandler
  def handle message
    puts "[MyClientHandler] #{ message.address }"
  end
end

puts "setting up client"
client = OSC::TCP::Client.new 'localhost', 52000, MyClientHandler.new

puts "sending spam"
client.send OSC::Message.new("/hello", "world")

sleep 1

# thread.join
