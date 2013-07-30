require 'spec_helper'

describe CharityGroup do

  before(:each) do
    @cg = CharityGroup.new
  end

  describe "validations" do
    it "should have a name" do
      @cg.charities << default_charity_1
      @cg.should_not be_valid
      @cg.should have(1).error_on(:name)
      @cg.name = "Kids"
      @cg.should be_valid
    end

    it "should have an unique name" do
      name = 'Greetings'
      cg = CharityGroup.new(:name => name)
      cg.charities << default_charity_1
      cg.should be_valid
      cg.save
      @cg.name = name
      @cg.charities << default_charity_1
      @cg.should_not be_valid
      @cg.should have(1).error_on(:name)
      @cg.name = 'greetings'
      @cg.should have(1).error_on(:name)
      @cg.should_not be_valid
      @cg.name = 'greetings2'
      @cg.should be_valid
    end

    it "should have charities" do
      @cg.name = "Kids"
      @cg.should_not be_valid
      @cg.should have(1).error_on(:charities)
      @cg.charities << default_charity_1
      @cg.should be_valid

    end
  end # end validations

  describe "create_with_charities" do
    it "should show errors on charity group and charities" do
      cg = CharityGroup.new_with_charities({})
      cg.should be_an_instance_of CharityGroup
      cg.should_not be_valid
      cg.should have(1).error_on(:charities)
      cg.should have(1).error_on(:name)
    end

    it "should show errors on charities" do
      cg = CharityGroup.new_with_charities({:name => 'Char'})
      cg.should_not be_valid
      cg.should have(1).error_on(:charities)
    end

    it "should show errors on name" do
      cg = CharityGroup.new_with_charities({:charity_ids => [default_charity_1.id]})
      cg.should_not be_valid
      cg.should have(1).error_on(:name)
    end

    it "should create associations" do
      cg = CharityGroup.new_with_charities({:name => 'valid name', :charity_ids => [default_charity_1.id, default_charity_2.id]})
      cg.reload
      cg.should be_valid
      cg.charities.should include(default_charity_1)
      cg.charities.should include(default_charity_2)
      cg.attributes.should_not include('charity_ids') # don't create a property of this
    end
  end #end create_with_charities

  describe "add_charity" do
    it "should add a charity" do
      c = default_charity_2
      cg = CharityGroup.new_with_charities( {:name => 'new charity', :charity_ids => [default_charity_1.id]} )
      cg.save
      cg.add_charity( c.id )
      test_charity = cg.charities.find( c.id )
      test_charity.name.should == c.name
    end 

    it "should fail because charity does not exist" do
      cg = CharityGroup.new_with_charities( {:name => 'new charity', :charity_ids => [default_charity_1.id]} )
      expect { cg.add_charity("38388834435652626") }.to raise_error
    end



  end #add_charity



end
