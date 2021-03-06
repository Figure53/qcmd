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
    tokens = Qcmd::Parser.parse 'go "word word" 10 (rate 10) 1'
    tokens.should eql([:go, 'word word', 10, [:rate, 10], 1])
  end

  it "should parse floats" do
    tokens = Qcmd::Parser.parse '1.1 go ("word word" 10.2 -12.3 1.1.1) 10.2'
    tokens.should eql([1.1, :go, ['word word', 10.2, -12.3, :'1.1.1'], 10.2])
  end

  it "should parse invalid numbers as symbols" do
    tokens = Qcmd::Parser.parse 'cue 1.11.0'
    tokens.should eql([:cue, :'1.11.0'])
  end

  it 'should parse modifiers as symbols' do
    tokens = Qcmd::Parser.parse 'cue number ++1 --1'
    tokens.should eql([:cue, :number, :'++1', :'--1'])
  end

  it "should parse nested quotes" do
    tokens = Qcmd::Parser.parse 'go "word word" 10 -12.3 "life \"is good\" yeah"'
    tokens.should eql([:go, 'word word', 10, -12.3, 'life "is good" yeah'])
  end

  it "should parse nested commands" do
    tokens = Qcmd::Parser.parse 'cue 10 name (cue 3 name)'
    tokens.should eql([:cue, 10, :name, [:cue, 3, :name]])
  end

  it "should parse nested commands with string literals" do
    tokens = Qcmd::Parser.parse 'alias cue-rename (cue $1 name "Hello World")'
    tokens.should eql([:alias, :'cue-rename', [:cue, :'$1', :name, 'Hello World']])
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

  it 'should parse multiple commands in a row' do
    tokens = Qcmd::Parser.parse '(copy-sliders 1 2) (echo "DONE!")'
    tokens.should eql([[:'copy-sliders', 1, 2], [:echo, "DONE!"]])
  end

  ## Generating

  describe "generating expressions" do
    it "should leave string literals intact" do
      expression = Qcmd::Parser.generate([:cue, :'$1', :name, 'Hello World'])
      expression.should eql('(cue $1 name "Hello World")')
    end

    it "should handle nesting" do
      expression = Qcmd::Parser.generate([:cue, :'$1', :name, [:cue, :'$2', :name]])
      expression.should eql('(cue $1 name (cue $2 name))')
    end

    it "should handle escaped double quotes" do
      expression = Qcmd::Parser.generate([:go, 'word word', 10, -12.3, 'life "is good" yeah'])
      expression.should eql('(go "word word" 10 -12.3 "life \"is good\" yeah")')
    end
  end
end
