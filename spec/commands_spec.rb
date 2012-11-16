require 'qcmd'
require 'osc-ruby'

describe Qcmd::Commands do
  describe 'cue commands' do
    before do
      Qcmd.context = Qcmd::Context.new
      Qcmd.context.machine = Qcmd::Machine.new('machine', '1.1.1.1', 1000)
      Qcmd.context.workspace_connected = true
    end

    describe 'cue command always needing reply' do
      before do
        @address = '/workspace/TEST/cue/1/isRunning'
      end

      describe 'with args' do
        before do
          @message = OSC::Message.new(@address, 123)
        end

        it 'is detected' do
          Qcmd::Commands.expects_reply?(@message).should eql(true)
        end
      end

      describe 'without args' do
        before do
          @message = OSC::Message.new(@address, *@args)
        end

        it 'is detected' do
          Qcmd::Commands.expects_reply?(@message).should eql(true)
        end
      end
    end
  end
end
