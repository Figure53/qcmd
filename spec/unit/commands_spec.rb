require 'qcmd'
require 'osc-ruby'

#
# This test file requires a running QLab instance with at least one cue. It is
# *strongly* recommended you just open a new QLab workspace and close all
# others.
#

def test_log msg=''
  puts msg
end

describe Qcmd::Commands do
  describe 'cue commands should not raise errors' do
    before do
      Qcmd.context = Qcmd::Context.new
      Qcmd.context.machine = machine = Qcmd::Machine.new('test machine', 'localhost', 53000)
      @sender = OSC::TCPClient.new machine.address, machine.port

      @thread = nil
    end

    after do
      if !@thread.nil? && @thread.alive?
        @thread.join
      end
    end

    describe 'machine commands' do
      it 'should not raise errors' do
        test_log

        Qcmd::Commands::MACHINE.each do |machine_command|
          expect {
            osc_message = OSC::Message.new "/#{ machine_command }"

            reply = nil

            # should be able to instantiate all OSC message reponses as QLab replies
            @sender.send(osc_message) do |response|
              reply = Qcmd::QLab::Reply.new(response)
              test_log "[machine command] #{ reply.address } got #{ reply.to_s }"
            end

            reply.should_not be_nil
          }.to_not raise_error
        end
      end
    end

    describe 'workspace commands' do
      before do
        # load workspaces
        osc_message = OSC::Message.new '/workspaces'
        @sender.send(osc_message) do |response|
          reply = Qcmd::QLab::Reply.new(response)
          Qcmd.context.machine.workspaces = reply.data.map {|ws| Qcmd::QLab::Workspace.new(ws)}
        end
      end

      it 'should not raise errors' do
        test_log

        workspace = Qcmd.context.machine.workspaces.first

        Qcmd::Commands::WORKSPACE.each do |workspace_command|
          expect {
            osc_message = OSC::Message.new "/workspace/#{workspace.id}/#{ workspace_command }"

            reply = nil

            @sender.send(osc_message) do |response|
              reply = Qcmd::QLab::Reply.new(response)
              test_log "[workspace command] #{ reply.address } got #{ reply.to_s }"
            end

            reply.should_not be_nil
          }.to_not raise_error
        end

        # spawn thread to shrink screen back down
        @thread = Thread.new do
          sleep 2
          @sender.send(OSC::Message.new("/workspace/#{workspace.id}/toggleFullScreen"))
        end
      end

      describe 'cue commands' do
        before do
          @cue = nil

          osc_message = OSC::Message.new "/workspace/#{ Qcmd.context.machine.workspaces.first.id }/cueLists"

          @sender.send(osc_message) do |response|
            reply = Qcmd::QLab::Reply.new(response)
            @cue = Qcmd::QLab::Cue.new(reply.data.first['cues'].first)
          end
        end

        it 'should not raise errors' do
          test_log

          workspace = Qcmd.context.machine.workspaces.first

          Qcmd::Commands::CUE.each do |cue_command|
            expect {
              osc_message = OSC::Message.new "/workspace/#{workspace.id}/cue/#{ @cue.number }/#{ cue_command }"

              reply = nil

              @sender.send(osc_message) do |response|
                reply = Qcmd::QLab::Reply.new(response)
                test_log "[cue command] #{ reply.address } got #{ reply.to_s }"
              end

              reply.should_not be_nil

            }.to_not raise_error
          end
        end
      end
    end
  end
end
