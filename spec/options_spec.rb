require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/../bin/options'

describe Rush::RushOptions do
  it "parses correctly the command if given in the command line" do
    options = Rush::RushOptions.new ['home.ls']
    options.command.should eql 'home.ls'
  end

  it "parses correctly the command if given in the command line" do
    options = Rush::RushOptions.new ['--', 'bash -x -- test.sh']
    options.command.should eql 'bash -x -- test.sh'
  end
end
