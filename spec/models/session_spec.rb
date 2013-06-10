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
  end #describe



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
  end #describe

  describe "timestamps" do
    it "should populate created_at and updated_at" do
      s = Session.create
      s.updated_at.should_not be_nil
      s.created_at.should_not be_nil
      s.updated_at.should be_within(2.second).of(Time.now)
      s.created_at.should be_within(2.second).of(Time.now)
    end


  end #describe





end

