require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/../lib/rush'

describe Rush::Shell do
  before do
    @shell = Rush::Shell.new(Rush::RushOptions.new([]))
  end

  after do
    @shell.clear_history
  end

  it "matches open path commands for readline tab completion" do
    @shell.path_parts("dir['app").should == [ "dir", "[", "'", "app", "" ]
    @shell.path_parts('dir/"app').should == [ "dir", "/", '"', "app", "" ]
  end

  it "matches open path commands on globals for readline tab completion" do
    @shell.path_parts("$dir['app").should == [ "$dir", "[", "'", "app", "" ]
    @shell.path_parts('$dir/"app').should == [ "$dir", "/", '"', "app", "" ]
  end

  it "matches open path commands on instance vars for readline tab completion" do
    @shell.path_parts("@dir['app").should == [ "@dir", "[", "'", "app", "" ]
    @shell.path_parts('@dir/"app').should == [ "@dir", "/", '"', "app", "" ]
  end

  it "interprets correctly single row commands" do
    @shell.stub(:readline).and_return("root.ls","exit")
    @shell.should_receive(:execute).with("root.ls")
    @shell.interactive_shell
  end

  it "interprets correctly multiple row commands" do
    @shell.should_receive(:readline).ordered.with("rush > ").and_return("root.ls\\")
    @shell.should_receive(:readline).ordered.with("-> ").and_return("home.ls")
    @shell.should_receive(:readline).ordered.with("rush > ").and_return("exit")
    @shell.should_receive(:execute).with("root.ls\nhome.ls")
    @shell.interactive_shell
  end
end
