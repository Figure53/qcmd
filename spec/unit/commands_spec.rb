require 'qcmd'
require 'osc-ruby'

describe Qcmd::Commands do
  describe 'cue commands' do
    before do
      Qcmd.context = Qcmd::Context.new
      Qcmd.context.machine = Qcmd::Machine.new('machine', '1.1.1.1', 1000)
      Qcmd.context.workspace_connected = true
    end
  end
end
