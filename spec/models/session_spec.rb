require 'spec_helper'

describe Session do

  describe "expired?" do
    it "should not be expired" do
      s = Session.new
      s.created_at = 2.hours.ago
      s.expired?.should == false
    end #it

    it "should be expired" do
      s = Session.new
      s.created_at = 5.hours.ago
      s.expired?.should == true
    end #it
  end # end expired?

  describe "indicate_activity" do
    it "should update updated_at" do
      s = Session.new
      s.updated_at.should be_nil
      s.indicate_activity!
      s.updated_at.should_not be_nil
    end

    it "should set updated_at to Time.now" do
      time = Time.now
      Time.stub(:now).and_return(time)
      s = Session.new
      s.indicate_activity!
      s.updated_at.to_i.should == time.to_i
    end
  end # end indicate_activity

  describe "timestamps" do
    it "should populate created_at and updated_at" do
      s = Session.create(:donor => default_donor)
      s.updated_at.should_not be_nil
      s.created_at.should_not be_nil
      s.updated_at.should be_within(2.second).of(Time.now)
      s.created_at.should be_within(2.second).of(Time.now)
    end
  end # end timestamps

  describe "generate_token" do
    it "should populate token at creation" do
      token = 'asdf1234'
      SecureRandom.stub(:urlsafe_base64).and_return(token)
      s = Session.create(:donor => default_donor)
      s.token.should_not be_nil
      s.token.should == token
    end

    it "should generate an unique token" do
      token = 'asdf1234'
      token2 = 'fdsa4321'
      SecureRandom.stub(:urlsafe_base64).and_return(token, token2)
      Session.should_receive(:find_by_token).with(token).and_return(true)
      Session.should_receive(:find_by_token).with(token2).and_return(false)
      s = Session.create(:donor => default_donor)
      s.token.should_not be_nil
      s.token.should == token2
    end
  end

end
