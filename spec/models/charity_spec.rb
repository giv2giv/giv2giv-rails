require 'spec_helper'

describe Charity do

  describe "validations" do
    it "should have an ein" do
      c = Charity.new
      c.should_not be_valid
      c.should have(1).error_on(:ein)
      c.ein = 12354
      c.should be_valid
    end

    it "should not allow duplicate ein" do
      ein = 12345
      Charity.create(:ein => ein)
      c = Charity.new(:ein => ein)
      c.should_not be_valid
      c.should have(1).error_on(:ein)
      c.ein = 23456
      c.should be_valid
    end
  end

end
