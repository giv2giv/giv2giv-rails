require 'spec_helper'

describe Endowment do

  describe "validations" do
    it "should have a name" do
      endowment = build(:endowment_with_charity, name: nil)
      endowment.should_not be_valid
      endowment.should have(1).error_on(:name)
      endowment.name = "Kids"
      endowment.should be_valid
    end

    it "should have an unique name" do
      name = 'Greetings'
      endowment = create(:endowment_with_charity, name: name)
      endowment.should be_valid

      endowment2 = build(:endowment_with_charity, name: name)
      endowment2.should_not be_valid
      endowment2.should have(1).error_on(:name)
      endowment2.name = 'greetings'
      endowment2.should have(1).error_on(:name)
      endowment2.should_not be_valid
      endowment2.name = 'greetings2'
      endowment.should be_valid
    end

  end # end validations

  describe "add_charity" do
    it "should add a charity" do
      c1 = create(:charity)
      endowment = create(:endowment)
      json_string = [{:id => c1.id}]
      endowment.add_charity( json_string )
      test_charity = endowment.charities.find( c1.id.to_s )
      test_charity.name.should == c1.name
    end 

  end #add_charity

end
