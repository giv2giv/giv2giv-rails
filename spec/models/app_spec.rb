require 'spec_helper'

describe App do

  before(:each) do
    App.reload!
  end

  it "should only call load once" do
    App.should_not_receive(:load) # referencing App already triggered the load
    App.dwolla.class.should == Hash
  end

  it "should allow a setting to be false" do
    App.settings = {'force_ssl' => false}
    App.force_ssl.should == false
  end

end
