require 'spec_helper'

describe Donor do

  describe "validations" do
    it "should be invalid without name" do
      donor = build(:donor, name: nil)
      donor.should_not be_valid
      donor.should have(1).error_on(:name)
      donor.name = 'Kendal'
      donor.should be_valid
    end

    it "should be invalid without valid email" do
      donor = build(:donor, email: nil)
      donor.should_not be_valid
      donor.should have(2).error_on(:email)
      donor.email = 'Kendal'
      donor.should_not be_valid
      donor.should have(1).error_on(:email)
      donor.email = 'Kendal@fake'
      donor.should_not be_valid
      donor.should have(1).error_on(:email)
      donor.email = 'kmiller2@ltc.com'
      donor.should be_valid
    end

    it "should be invalid without password" do
      donor = build(:donor, password: nil)
      donor.should_not be_valid
      donor.should have(1).error_on(:password)
      donor.password = 'yeah'
      donor.should be_valid
    end

    it "should be invalid without accepting terms and conditions" do
      donor = build(:donor, accepted_terms: nil)
      donor.should_not be_valid
      donor.should have(1).error_on(:accepted_terms)
      donor.accepted_terms = true
      donor.should be_valid
    end

    it "should be invalid without accepting terms and conditions datetime" do
      donor = build(:donor, accepted_terms_on: nil)
      donor.should_not be_valid
      donor.should have(1).error_on(:accepted_terms_on)
      donor.accepted_terms_on = DateTime.now
      donor.should be_valid
    end

    it "should not allow duplicate email" do
      donor = create(:donor)

      donor2 = build(:donor, email: donor.email)
      donor2.should_not be_valid
      donor2.should have(1).error_on(:email)

      donor3 = build(:donor, email: donor.email.upcase)
      donor3.should_not be_valid
      donor3.should have(1).error_on(:email)
    end
  end # end validations

  describe "authentication" do
    it "should not store password in plaintext" do
      pass = 'passwerd'
      donor = create(:donor, password: pass)
      donor.reload
      donor.password.to_s.should_not equal pass
    end

    it "should compare password to hash" do
      pass = 'passwerd'
      donor = create(:donor, password: pass)
      donor.reload
      donor.password.to_s.should_not equal pass
      (donor.password == pass).should be true
      (donor.password == 'not password').should be false
    end

    it "should authenticate successfully" do
      email = 'nocoll@ltc.com'
      pass = 'passwerd'
      donor = create(:donor, email: email, password: pass)

      e = Donor.authenticate(email, pass)
      e.should be_an_instance_of Donor
      e.email.should == email
    end

    it "should not authenticate" do
      donor = create(:donor)

      e = Donor.authenticate(donor.email, 'hmm')
      e.should_not be_an_instance_of Donor
      e.should be_nil
    end

    it "should not choke on nil" do
      e = Donor.authenticate(nil, nil)
      e.should_not be_an_instance_of Donor
      e.should be_nil
    end

    it "should not raise error if user not found" do
      email = 'notfound@ltc.com'
      donor = Donor.find_by_email(email)
      donor.should be_nil
      e = Donor.authenticate(email, 'asdf')
      e.should_not be_an_instance_of Donor
      e.should be_nil
    end

    it "should not explode with npe if it has a space" do
      email = "space space"
      donor = Donor.find_by_email(email)
      donor.should be_nil
    end
  end # end authentication

  describe "behavior" do
    it "should have created_at and updated_at" do
      donor = build(:donor)
      donor.created_at.should be_nil
      donor.updated_at.should be_nil
      donor.save!
      donor.created_at.should_not be_nil
      donor.created_at.should be_within(2.seconds).of(Time.now)
      donor.updated_at.should_not be_nil
      donor.updated_at.should be_within(2.seconds).of(Time.now)
    end

    it "should link donor and donation" do
      donor = create(:donor_with_donation)
      donation = donor.donations.first
      donation.donor.should == donor
    end

    context "find_by_email" do
      it "should not raise error if email is nil" do
        email = nil
        donor = Donor.find_by_email(email)
        donor.should be_nil
      end

      it "should not raise error if email is blank" do
        email = " "
        donor = Donor.find_by_email(email)
        donor.should be_nil
      end

      it "should return user if user exists" do
        d = create(:donor)
        d.should be_valid
        donor = Donor.find_by_email(d.email)
        donor.should_not be_nil
        donor.should == d
      end
    end
  end # end behavior

end
