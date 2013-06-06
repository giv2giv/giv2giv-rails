require 'spec_helper'

describe CharityGroup do

  before(:each) do
    @cg = CharityGroup.new
  end

  describe "validations" do
    it "should have a name" do
      @cg.should_not be_valid
      @cg.should have(1).error_on(:name)
      @cg.name = "Kids"
      @cg.should be_valid
    end

    it "should have an unique name" do
      name = 'Greetings'
      CharityGroup.create(:name => name)
      @cg.name = name
      @cg.should_not be_valid
      @cg.should have(1).error_on(:name)
      @cg.name = 'greetings'
      @cg.should have(1).error_on(:name)
      @cg.should_not be_valid
      @cg.name = 'greetings2'
      @cg.should be_valid
    end
  end
end
