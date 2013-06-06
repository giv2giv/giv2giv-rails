require 'spec_helper'

describe Donation do

  valid_donation_attributes = {:amount => '20',
                               :transaction_id => '51413121',
                               :transaction_processor => 'me',
                               :donor => Donor.new}

  before(:each) do
    @donation = Donation.new
  end

  describe "validations" do
    it "should have an amount" do
      @donation.attributes = valid_donation_attributes.except(:amount)
      @donation.should_not be_valid
      @donation.should have(1).error_on(:amount)
      @donation.amount = 10
      @donation.should be_valid
    end

    it "should have a transaction_id" do
      @donation.attributes = valid_donation_attributes.except(:transaction_id)
      @donation.should_not be_valid
      @donation.should have(1).error_on(:transaction_id)
      @donation.transaction_id = 'ASDF1234'
      @donation.should be_valid
    end

    it "should have a transaction_processor" do
      @donation.attributes = valid_donation_attributes.except(:transaction_processor)
      @donation.should_not be_valid
      @donation.should have(1).error_on(:transaction_processor)
      @donation.transaction_processor = 'dwolla'
      @donation.should be_valid
    end

    it "should have a donor" do
      @donation.attributes = valid_donation_attributes.except(:donor)
      @donation.should_not be_valid
      @donation.should have(1).error_on(:donor)
      @donation.donor = Donor.new
      @donation.should be_valid
    end
  end # end validations

end
