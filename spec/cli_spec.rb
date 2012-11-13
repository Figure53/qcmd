require 'qcmd'

describe Qcmd::CLI do
  it "should call `start` when initialized" do
    Qcmd::CLI.any_instance.stub(:start) { true }
    Qcmd::CLI.any_instance.should_receive(:start)
    Qcmd::CLI.new
  end
end
