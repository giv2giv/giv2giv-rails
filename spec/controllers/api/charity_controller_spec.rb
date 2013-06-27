require 'spec_helper'

describe Api::CharityController do

  before(:each) do
   @c1 = default_charity_1
  end

  describe "index" do
    it "should not require prior authentication" do
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp.first['name'].should == default_charity_1.name
    end

    it "should work" do
      setup_authenticated_session
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp.first['name'].should == default_charity_1.name
    end
  end # end show

  describe "show" do
    it "should not require prior authentication" do
      get :show, :format => :json, :id => @c1.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @c1.name
      resp['id'].should == @c1.id
      resp['ein'].should == @c1.ein
    end

    it "should work" do
      setup_authenticated_session
      get :show, :format => :json, :id => @c1.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @c1.name
      resp['id'].should == @c1.id
      resp['ein'].should == @c1.ein
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      Charity.find(id).should be_nil
      get :show, :format => :json, :id => id
      response.status.should == 404
    end
  end
end
