require 'spec_helper'

describe Endowment do

  describe "validations" do
    it "should have a name" do
      cg = build(:endowment_with_charity, name: nil)
      cg.should_not be_valid
      cg.should have(1).error_on(:name)
      cg.name = "Kids"
      cg.should be_valid
    end

    it "should have an unique name" do
      name = 'Greetings'
      cg = create(:endowment_with_charity, name: name)
      cg.should be_valid

      cg2 = build(:endowment_with_charity, name: name)
      cg2.should_not be_valid
      cg2.should have(1).error_on(:name)
      cg2.name = 'greetings'
      cg2.should have(1).error_on(:name)
      cg2.should_not be_valid
      cg2.name = 'greetings2'
      cg.should be_valid
    end

  end # end validations

  describe "add_charity" do
    it "should add a charity" do
      c1 = create(:charity)
      cg = create(:endowment)
      cg.add_charity( c1.id.to_s )
      test_charity = cg.charities.find( c1.id.to_s )
      test_charity.name.should == c1.name
    end 

  end #add_charity

end
