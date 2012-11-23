require File.join( File.dirname(__FILE__) , '..', 'spec_helper' )
require 'qcmd'
require 'socket'

class PortFactory
  @@counter = 12345

  def self.new_port
    @@counter += 1
    @@counter
  end
end

describe OSC::StoppingServer do
  before :each do
    @port = PortFactory.new_port
  end

  it "should bind to a socket when initialized" do
    UDPSocket.any_instance.should_receive(:bind).with('', @port)
    server = OSC::StoppingServer.new @port
  end

  it 'should start a listening thread when started' do
    server = OSC::StoppingServer.new @port

    test_thread = Thread.new do
      Thread.should_receive :fork
      server.run
    end

    server.stop
  end

  it 'should kill the listening thread and close socket when stopped' do
    server = OSC::StoppingServer.new @port

    test_thread = Thread.new do
      server.run
    end

    sleep 0.1
    server.stop
    sleep 0.1

    # server has stopped blocking
    test_thread.alive?.should == false

    # server claims it is closed
    server.state.should == :stopped
  end

  it 'should create messages for legitimate OSC commands' do
    server = OSC::StoppingServer.new @port

    received = nil

    server.add_method '/test' do |message|
      received = message
    end

    test_thread = Thread.new do
      server.run
    end

    received.should == nil

    client = OSC::Client.new 'localhost', @port
    client.send OSC::Message.new('/test', 'ansible')

    sleep 0.1
    server.stop

    received.is_a?(OSC::Message).should == true
    received.to_a.first.should == 'ansible'
  end
end

