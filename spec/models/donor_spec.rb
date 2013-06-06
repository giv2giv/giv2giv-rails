require 'spec_helper'

describe Donor do

  valid_donor_attributes = {:email => 'kmiller@ltc.com',
                            :name => 'Kendal',
                            :password => 'thepassword'}

  before(:each) do
    @donor = Donor.new
  end

  describe "validations" do
    it "should be invalid without name" do
      @donor.attributes = valid_donor_attributes.except(:name)
      @donor.should_not be_valid
      @donor.should have(1).error_on(:name)
      @donor.name = 'Kendal'
      @donor.should be_valid
    end

    it "should be invalid without valid email" do
      @donor.attributes = valid_donor_attributes.except(:email)
      @donor.should_not be_valid
      @donor.should have(2).error_on(:email)
      @donor.email = 'Kendal'
      @donor.should_not be_valid
      @donor.should have(1).error_on(:email)
      @donor.email = 'Kendal@fake'
      @donor.should_not be_valid
      @donor.should have(1).error_on(:email)
      @donor.email = 'kmiller2@ltc.com'
      @donor.should be_valid
    end

    it "should be invalid without password" do
      @donor.attributes = valid_donor_attributes.except(:password)
      @donor.should_not be_valid
      @donor.should have(1).error_on(:password_hash)
      @donor.password = password = 'yeah'
      @donor.should be_valid
    end

    it "should not allow duplicate email" do
      @donor.attributes = valid_donor_attributes.except(:email)
      @donor.email = email = 'nocol@ltc.com'
      @donor.should be_valid
      @donor.save
      e = Donor.new
      e.attributes = valid_donor_attributes.except(:email)
      e.email = email
      e.should_not be_valid
      e.should have(1).error_on(:email)
      e = Donor.new
      e.attributes = valid_donor_attributes.except(:email)
      e.email = email.upcase
      e.should_not be_valid
      e.should have(1).error_on(:email)
    end
  end # end validations

  describe "authentication" do
    it "should not store password in plaintext" do
      @donor.attributes = valid_donor_attributes.except(:password)
      @donor.password = pass = 'passwerd'
      @donor.password_hash.should_not equal pass
      @donor.password_hash.split('$').length.should be > 1 # bcrypt uses $ as delimiter...better be multiple parts!
    end

    it "should compare password to hash" do
      pass = valid_donor_attributes[:password]
      @donor.attributes = valid_donor_attributes
      @donor.password.to_s.split('$').length.should be > 1
      @donor.password.to_s.should_not equal pass
      (@donor.password == pass).should be true
      (@donor.password == 'not password').should be false
    end

    it "should authenticate successfully" do
      @donor.attributes = valid_donor_attributes.except(:email)
      @donor.email = email = 'nocoll@ltc.com'
      @donor.should be_valid
      @donor.save
      e = Donor.authenticate(email, valid_donor_attributes[:password])
      e.should be_an_instance_of Donor
      e.email.should == email
    end

    it "should not authenticate" do
      @donor.attributes = valid_donor_attributes.except(:email)
      @donor.email = email = 'nocoll2@ltc.com'
      @donor.should be_valid
      @donor.save
      e = Donor.authenticate(email, 'hmm')
      e.should_not be_an_instance_of Donor
      e.should be_nil
    end
  end # end authentication

  describe "behavior" do
    it "should have created_at and updated_at" do
      @donor.attributes = valid_donor_attributes.except(:email)
      @donor.email = email = 'nocoll3@ltc.com'
      @donor.should be_valid
      @donor.created_at.should be_nil
      @donor.updated_at.should be_nil
      @donor.save
      @donor.created_at.should_not be_nil
      @donor.created_at.should be_within(2.seconds).of(Time.now)
      @donor.updated_at.should_not be_nil
      @donor.updated_at.should be_within(2.seconds).of(Time.now)
    end

    it "should link donor and donation" do
      @donor.attributes = valid_donor_attributes.merge(:dwolla_token => 'token', :email => 'nocoll4@ltc.com')
      @donor.should be_valid
      @donor.dwolla_token.should_not be_nil
      # mock out dwolla stuff
      donation = @donor.donations.build(:amount => 5, :transaction_id => 12345, :transaction_processor => 'me')
      donation.should be_valid
      donation.donor.should == @donor # did the relationship get created?
      @donor.donations.should include(donation)
    end

  end # end behavior

end
