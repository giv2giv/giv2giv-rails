require 'spec_helper'

describe Api::DonorsController do

  before(:each) do
    @donor = create(:donor)
  end

  describe "create" do
    it "should create donor on success" do
      Donor.should_receive(:new).and_return(@donor)
      post :create, :format => :json, :donor => {:password => "passwerd", :accept_terms => "true"}

      response.status.should == 201
      resp = JSON.parse(response.body)["donor"]
      resp['email'].should == @donor.email
      resp['name'].should == @donor.name
    end

    it "should include errors on failure" do
      @donor.email = nil
      @donor.should_not be_valid
      Donor.should_receive(:new).and_return(@donor)

      post :create, :format => :json, :donor => {:password => "passwerd"}
      response.should_not be_success
      resp = JSON.parse(response.body)
      resp['email'].should_not be_blank
    end

    it "should work" do
      params = {:name => 'Kendal',
                :password => 'welcome',
                :email => 'dc@ltc.com',
                :accept_terms => 'true'}
      post :create, :format => :json, :donor => params
      response.status.should == 201
      resp = JSON.parse(response.body)["donor"]
      resp['email'].should == params[:email]
      resp['name'].should == params[:name]
    end
  end # end create

  describe "update" do
    it "should require prior authentication" do
      put :update, :format => :json
      response.status.should == 401
    end

    it "should include errors on failure" do
      setup_authenticated_session
      @donor.name = nil
      @donor.should_not be_valid
      errors = @donor.errors
      Donor.any_instance.should_receive(:update_attributes).and_return(false)
      Donor.any_instance.should_receive(:errors).and_return(errors)

      put :update, :format => :json
      response.status.should == 422
      resp = JSON.parse(response.body)
      resp['name'].should_not be_blank
    end

    it "should be successful" do
      setup_authenticated_session
      Donor.any_instance.should_receive(:update_attributes).and_return(true)

      put :update, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)["donor"]
      resp['name'].should == @donor.name
    end
  end # end update

  describe "show" do
    it "should require prior authentication" do
      get :show, :format => :json
      response.status.should == 401
    end

    it "should be successful" do
      setup_authenticated_session
      get :show, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)["donor"]
      resp['name'].should == @donor.name
    end
  end


end
