require 'qcmd'

describe Qcmd do
  # tests go here
  it "should log debug messages when in verbose mode" do
    Qcmd.should_receive(:log).with('hello')
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

  it 'should not log debug messages when in quiet block' do
    Qcmd.verbose!
    Qcmd.log_level.should eql(:debug)

    Qcmd.while_quiet do
      Qcmd.should_not_receive(:log)
      Qcmd.log_level.should eql(:warning)
      Qcmd.debug 'hello'
    end

    Qcmd.log_level.should eql(:debug)
  end
end
