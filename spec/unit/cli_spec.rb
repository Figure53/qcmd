require 'qcmd'

class NonStarter
  def start
  end
end

describe Qcmd::CLI do
  it 'should init on launch' do
    Qcmd::CLI.stub(:new) { NonStarter.new }
    Qcmd::CLI.should_receive :new
    Qcmd::CLI.launch
  end

  describe 'replace_args' do
    it 'should replace args in alias expression with values of given type' do
      cli = Qcmd::CLI.new
      new_command = cli.replace_args [:cue, :'$1', :name, "hello $2"], [:at, 2, 3]
      new_command.should eql([:cue, 2, :name, "hello 3"])
    end
  end
end
