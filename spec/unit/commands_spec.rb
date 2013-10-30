require 'qcmd'
require 'osc-ruby'

#
# This test file requires a running QLab instance with at least one cue. It is
# *strongly* recommended you open a new QLab workspace and close all others
# before running the tests.
#

def test_log msg=''
  # puts msg
end

class DeadHandler
  def self.handle response
    # do nothing :P
  end
end

describe Qcmd::Commands do
  describe 'when sending messages' do
    before do
      Qcmd.context = Qcmd::Context.new
      Qcmd.context.machine = Qcmd::Machine.new('test machine', 'localhost', 53000)
      Qcmd.context.connect_to_qlab DeadHandler

      # make sure alwaysReply is turned on
      Qcmd.context.qlab.send(OSC::Message.new('/alwaysReply', 1))

      @thread = nil
    end

    after do
      if !@thread.nil? && @thread.alive?
        @thread.join
      end
    end

    describe 'machine commands' do
      it 'should not raise errors' do
        Qcmd.context.machine_connected?.should be_true
        test_log

        Qcmd::Commands::MACHINE.each do |machine_command|
          expect {
            osc_message = OSC::Message.new "/#{ machine_command }", 1

            reply = nil

            test_log "[machine_command] sending #{ machine_command } - #{ osc_message.address } #{ osc_message.to_a.inspect }"

            # should be able to instantiate all OSC message reponses as QLab replies
            Qcmd.context.qlab.send(osc_message) do |response|
              # test_log "[machine command] response: #{ response.inspect }"
              reply = Qcmd::QLab::Reply.new(response)
              # test_log "[machine command] #{ reply.address } got #{ reply.to_s }"
            end

            reply.should_not be_nil
            # test_log reply.address

          }.to_not raise_error
        end
      end
    end

    describe 'workspace commands' do
      before do
        # make sure alwaysReply is turned on
        Qcmd.context.qlab.send(OSC::Message.new('/alwaysReply', 1))

        # load workspaces
        osc_message = OSC::Message.new '/workspaces'
        Qcmd.context.qlab.send(osc_message) do |response|
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

            osc_response = nil
            reply = nil

            begin
              Qcmd.context.qlab.send(osc_message) do |response|
                osc_response = response
                reply = Qcmd::QLab::Reply.new(response)
                # test_log "[workspace command] #{ reply.address } got #{ reply.to_s }"
              end
            rescue => ex
              puts "sender fail: #{ ex.message }"
              raise
            end

            begin
              test_log reply.address
              reply.should_not(be_nil)
            rescue => ex
              puts "reply access fail '#{ ex.message }' on response #{ osc_response.inspect }"
              raise
            end

          }.to_not raise_error
        end

        # spawn thread to shrink screen back down
        @thread = Thread.new do
          sleep 2
          Qcmd.context.qlab.send(OSC::Message.new("/workspace/#{workspace.id}/toggleFullScreen"))
        end
      end

      describe 'cue commands' do
        before do
          @cue = nil

          osc_message = OSC::Message.new "/workspace/#{ Qcmd.context.machine.workspaces.first.id }/cueLists"

          Qcmd.context.qlab.send(osc_message) do |response|
            reply = Qcmd::QLab::Reply.new(response)
            @cue  = Qcmd::QLab::Cue.new(reply.data.first['cues'].first)

            test_log "pulling cue from data: #{ reply.data.inspect }"
          end
        end

        it 'should not raise errors' do
          test_log

          workspace = Qcmd.context.machine.workspaces.first

          Qcmd::Commands::CUE.each do |cue_command|
            expect {
              test_log "using cue #{ @cue } : #{ @cue.data.inspect }"
              cmd = "/workspace/#{workspace.id}/cue/#{ @cue.number }/#{ cue_command }"

              test_log "sending #{ cmd }"
              osc_message = OSC::Message.new cmd

              osc_response = nil
              reply = nil

              Qcmd.context.qlab.send(osc_message) do |response|
                osc_response = response
                reply = Qcmd::QLab::Reply.new(response)
              end

              begin
                test_log reply.address
                reply.should_not be_nil
              rescue => ex
                test_log "reply access fail '#{ ex.message }' on response #{ osc_response.inspect }"
                raise
              end

            }.to_not raise_error
          end
        end
      end
    end
  end
end
