require 'spec_helper'

describe SessionsController do

  describe "creation" do
    it "should not create new session on auth failure" do
      Donor.stub(:authenticate).and_return(nil)
      get :create, :format => :json
      response.body.should == "Session creation failed"
    end

    it "should create new session on auth success" do
      session_id = 5
      Session.stub(:create).and_return(OpenStruct.new(:id => session_id))

      Donor.stub(:authenticate).and_return(Donor.new(:email => 'jim@jim.com'))
      get :create, :format => :json
      response.body.should == "Successfully created session"
      session[:session_id].should == session_id
    end


  end #describe

  describe "destroy" do
    it "should destroy an existing session" do
      email = 'jim@jim.com'
      session[:session_iid] = email
      get :destroy, :format => :json
      response.body.should == "Session destroyed"
      session[:session_id].should be_nil
    end
  end


end
