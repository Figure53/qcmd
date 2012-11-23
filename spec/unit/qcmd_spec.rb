require 'qcmd'

describe Qcmd do
  # tests go here
  it "should log debug messages when in verbose mode" do
    Qcmd.should_receive(:log, 'hello')

    Qcmd.verbose!
    Qcmd.log_level.should eql(:debug)
    Qcmd.debug 'hello'
  end

  it 'should not log debug messages when not in verbose mode' do
    Qcmd.should_not_receive(:log)
    Qcmd.quiet!
    Qcmd.log_level.should eql(:warning)
    Qcmd.debug 'hello'
  end
end
