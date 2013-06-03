require 'spec_helper'

valid_charity_attributes = {:name => 'BYOB',
                            :ein => 91817}

describe Charity do

  before(:each) do
    @charity = Charity.new
  end

  describe "validations" do
    it "should have an ein" do
      @charity.attributes = valid_charity_attributes.except(:ein)
      @charity.should_not be_valid
      @charity.should have(1).error_on(:ein)
      @charity.ein = 12354
      @charity.should be_valid
    end

    it "should not allow duplicate ein" do
      ein = '12345'
      Charity.create(:name => 'asdf', :ein => ein)
      @charity.attributes = {:name => 'asdf', :ein => ein}
      @charity.should_not be_valid
      @charity.should have(1).error_on(:ein)
      @charity.ein = 23456
      @charity.should be_valid
    end

    it "should have a name" do
      @charity.attributes = valid_charity_attributes.except(:name)
      @charity.should_not be_valid
      @charity.should have(1).error_on(:name)
      @charity.name = "Awk"
      @charity.should be_valid
    end
  end

end
