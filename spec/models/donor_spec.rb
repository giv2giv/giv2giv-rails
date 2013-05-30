require 'spec_helper'

valid_donor_attributes = {:email => 'kmiller@ltc.com',
                          :name => 'Kendal',
                          :password => 'thepassword'}

describe Donor do

  describe "validations" do
    it "should be invalid without name" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:name)
      d.should_not be_valid
      d.should have(1).error_on(:name)
      d.name = 'Kendal'
      d.should be_valid
    end

    it "should be invalid without valid email" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:email)
      d.should_not be_valid
      d.should have(2).error_on(:email)
      d.email = 'Kendal'
      d.should_not be_valid
      d.should have(1).error_on(:email)
      d.email = 'Kendal@fake'
      d.should_not be_valid
      d.should have(1).error_on(:email)
      d.email = 'kmiller2@ltc.com'
      d.should be_valid
    end

    it "should be invalid without password" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:password)
      d.should_not be_valid
      d.should have(1).error_on(:password_hash)
      d.password = password = 'yeah'
      d.should be_valid
    end

    it "should not allow duplicate email" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:email)
      d.email = email = 'nocol@ltc.com'
      d.should be_valid
      d.save
      e = Donor.new
      e.attributes = valid_donor_attributes.except(:email)
      e.email = email
      e.should_not be_valid
      e.should have(1).error_on(:email)
    end
  end # end validations

  describe "authentication" do
    it "should not store password in plaintext" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:password)
      d.password = pass = 'passwerd'
      d.password_hash.should_not equal pass
      d.password_hash.split('$').length.should be > 1 # bcrypt uses $ as delimiter...better be multiple parts!
    end

    it "should compare password to hash" do
      pass = valid_donor_attributes[:password]
      d = Donor.new
      d.attributes = valid_donor_attributes
      d.password.to_s.split('$').length.should be > 1
      d.password.to_s.should_not equal pass
      (d.password == pass).should be true
      (d.password == 'not password').should be false
    end

    it "should authenticate successfully" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:email)
      d.email = email = 'nocoll@ltc.com'
      d.should be_valid
      d.save
      d = Donor.authenticate(email, valid_donor_attributes[:password])
      d.should be_an_instance_of Donor
      d.email.should == email
    end

    it "should not authenticate" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:email)
      d.email = email = 'nocoll2@ltc.com'
      d.should be_valid
      d.save
      d = Donor.authenticate(email, 'hmm')
      d.should_not be_an_instance_of Donor
      d.should be_nil
    end
  end # end authentication

  describe "behavior" do
    it "should have created_at and updated_at" do
      d = Donor.new
      d.attributes = valid_donor_attributes.except(:email)
      d.email = email = 'nocoll3@ltc.com'
      d.should be_valid
      d.created_at.should be_nil
      d.updated_at.should be_nil
      d.save
      d.created_at.should_not be_nil
      d.created_at.should be_within(2.seconds).of(Time.now)
      d.updated_at.should_not be_nil
      d.updated_at.should be_within(2.seconds).of(Time.now)
    end
  end

end
