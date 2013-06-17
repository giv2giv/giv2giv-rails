require 'spec_helper'

describe Api::SessionsController do

  describe "create" do
    it "should not create new session on auth failure" do
      Session.should_not_receive(:create)
      Donor.stub(:authenticate).and_return(nil)
      post :create, :format => :json, :email => 'meh', :password => 'meh'
      response.status.should == 401
      response.body.should be_blank
    end

    it "should create new session on auth success" do
      sess = Session.create(:donor => default_donor)
      Session.stub(:create).and_return(sess)
      Donor.stub(:authenticate).and_return(Donor.new(:email => 'jim@jim.com'))
      post :create, :format => :json, :email => 'meh', :password => 'meh'
      response.status.should == 201
      resp = JSON.parse(response.body)
      resp['token'].should == sess.token
    end
  end # end create

  describe "destroy" do
    it "should destroy with token" do
      sess = Session.create(:donor => default_donor)
      token = sess.token
      sess.should_not be_nil
      request.env['HTTP_AUTHORIZATION'] = "Token token=#{token}"
      Session.should_receive(:find_by_token).once.with(token).and_return(sess)
      post :destroy, :format => :json
      response.status.should == 200
      response.body.should be_blank
    end

    it "should destroy with bad token" do
      token = '12345asdf'
      Session.find_by_token(token).should be_nil
      request.env['HTTP_AUTHORIZATION'] = "Token token=#{token}"
      Session.should_receive(:find_by_token).once.with(token).and_return(nil)
      post :destroy, :format => :json
      response.status.should == 200
      response.body.should be_blank
    end

    it "should destroy without token" do
      Session.should_not_receive(:find_by_token)
      post :destroy, :format => :json
      response.status.should == 200
      response.body.should be_blank
    end
  end # end destroy

end
