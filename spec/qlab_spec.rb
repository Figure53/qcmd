require 'qcmd'

describe Qcmd::QLab do
  it "has a workspace model" do
    ws = Qcmd::QLab::Workspace.new({
      'displayName' => 'name',
      'hasPasscode' => false,
      'uniqueID' => 'id'
    })

    ws.name.should eql('name')
    ws.passcode?.should eql(false)
    ws.id.should eql('id')
  end
end
