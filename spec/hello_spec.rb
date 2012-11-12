require 'qcmd'

describe Qcmd::Hello do
  it "should use hello world as the default phrase" do
    Qcmd::Hello.phrase.should eql('hello world')
  end
end
