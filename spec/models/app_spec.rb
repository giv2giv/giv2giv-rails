require 'spec_helper'

describe App do
  it "should only call load once" do
    App.should_not_receive(:load) # referencing App already triggered the load
    App.dwolla.class.should == Hash
  end

end
