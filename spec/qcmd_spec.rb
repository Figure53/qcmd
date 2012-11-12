require 'qcmd'

describe Qcmd do
  it "should respond to hello" do
    Qcmd.should respond_to(:hello)
  end
end
