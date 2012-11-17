require 'qcmd'

describe Qcmd::Parser do
  it "should parse simple commands" do
    tokens = Qcmd::Parser.parse "go"
    tokens.should eql(['go'])
  end

  it "should parse embedded strings" do
    tokens = Qcmd::Parser.parse 'go "word word"'
    tokens.should eql(['go', 'word word'])
  end

  it "should parse integers" do
    tokens = Qcmd::Parser.parse 'go "word word" 10'
    tokens.should eql(['go', 'word word', 10])
  end

  it "should parse floats" do
    tokens = Qcmd::Parser.parse 'go "word word" 10 -12.3'
    tokens.should eql(['go', 'word word', 10, -12.3])
  end

  it "should parse nested quotes" do
    tokens = Qcmd::Parser.parse 'go "word word" 10 -12.3 "life \"is good\" yeah"'
    tokens.should eql(['go', 'word word', 10, -12.3, 'life "is good" yeah'])
  end
end
