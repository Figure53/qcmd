require 'qcmd'

describe Qcmd::Parser do
  it "should parse simple commands" do
    tokens = Qcmd::Parser.parse "go"
    tokens.should eql([:go])
  end

  it "should parse embedded strings" do
    tokens = Qcmd::Parser.parse 'go "word word"'
    tokens.should eql([:go, 'word word'])
  end

  it "should parse integers" do
    tokens = Qcmd::Parser.parse 'go "word word" 10'
    tokens.should eql([:go, 'word word', 10])
  end

  it "should parse floats" do
    tokens = Qcmd::Parser.parse 'go "word word" 10 -12.3'
    tokens.should eql([:go, 'word word', 10, -12.3])
  end

  it "should parse nested quotes" do
    tokens = Qcmd::Parser.parse 'go "word word" 10 -12.3 "life \"is good\" yeah"'

    tokens.should eql([:go, 'word word', 10, -12.3, 'life "is good" yeah'])
  end

  it "should parse nested commands" do
    tokens = Qcmd::Parser.parse 'cue 10 name (cue 3 name)'
    tokens.should eql([:cue, 10, :name, [:cue, 3, :name]])
  end

  it "should parse alias commands" do
    tokens = Qcmd::Parser.parse 'alias copy-name (cue 10 name (cue 3 name))'
    tokens.should eql([:alias, :'copy-name', [:cue, 10, :name, [:cue, 3, :name]]])
  end

  it "should parse non alphanumeric commands" do
    tokens = Qcmd::Parser.parse '..'
    tokens.should eql([:'..'])
  end

  it "should parse leading slash commands" do
    tokens = Qcmd::Parser.parse '/alwaysReply 1'
    tokens.should eql([:'/alwaysReply', 1])
  end

  it 'should parse commands containing slashes' do
    tokens = Qcmd::Parser.parse 'workspace/124/connect'
    tokens.should eql([:'workspace/124/connect'])
  end

  it 'should parse strings with parens' do
    tokens = Qcmd::Parser.parse %[cue 1 name "this is (not good)"]
    tokens.should eql([:cue, 1, :name, 'this is (not good)'])
  end
end
