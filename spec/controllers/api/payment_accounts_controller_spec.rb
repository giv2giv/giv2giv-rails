require 'spec_helper'

describe Api::PaymentAccountsController do

  before(:each) do
    @donor = default_donor
    @pa = default_payment_account
  end

  describe "index" do
    it "should require prior authentication" do
      get :index, :format => :json
      response.status.should == 401
    end

    it "should work" do
      setup_authenticated_session
      get :index, :format => :json
      resp = JSON.parse(response.body)
      resp.class.should == Array
      resp = resp.first
      resp['id'].should == @pa.id
      resp['processor'].should == @pa.processor
      resp['token'].should == @pa.token
    end
  end # end index

  describe "create" do
    it "should require prior authentication" do
      post :create, :format => :json
      response.status.should == 401
    end

    it "should include errors on failure" do
      setup_authenticated_session
      post :create, :format => :json, :payment_account => {}
      response.status.should == 422
      resp = JSON.parse(response.body)
      resp['processor'].should_not be_blank
    end

    it "should work" do
      params = {:processor => 'Cat',
                :token => 'meowmeowmeow'}
      setup_authenticated_session
      post :create, :format => :json, :payment_account => params
      response.status.should == 201
      resp = JSON.parse(response.body)
      resp['id'].should_not be_blank
      resp['token'].should == params[:token]
    end
  end # end create

  describe "update" do
    it "should require prior authentication" do
      put :update, :format => :json, :id => @pa.id
      response.status.should == 401
    end

    it "should include errors on failure" do
      setup_authenticated_session
      put :update, :format => :json, :id => @pa.id, :payment_account => {:processor => ''}
      response.status.should == 422
      resp = JSON.parse(response.body)
      resp['processor'].should_not be_blank
    end

    it "should work" do
      params = {:processor => 'Cat',
                :token => 'meowmeowmeowaaaaaaa'}
      setup_authenticated_session
      put :update, :format => :json, :id => @pa.id, :payment_account => params
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['id'].should_not be_blank
      resp['token'].should == params[:token]
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      PaymentAccount.find(id).should be_nil
      put :update, :format => :json, :id => id
      response.status.should == 404
    end
  end # end update

  describe "show" do
    it "should require prior authentication" do
      get :show, :format => :json, :id => @pa.id
      response.status.should == 401
    end

    it "should work" do
      setup_authenticated_session
      get :show, :format => :json, :id => @pa.id
      resp = JSON.parse(response.body)
      resp['id'].should == @pa.id
      resp['processor'].should == @pa.processor
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      PaymentAccount.find(id).should be_nil
      get :show, :format => :json, :id => id
      response.status.should == 404
    end
  end # end show

  describe "destroy" do
    it "should require prior authentication" do
      delete :destroy, :format => :json, :id => @pa.id
      response.status.should == 401
    end

    it "should work" do
      setup_authenticated_session
      PaymentAccount.any_instance.should_receive(:destroy)
      delete :destroy, :format => :json, :id => @pa.id
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      PaymentAccount.find(id).should be_nil
      delete :destroy, :format => :json, :id => id
      response.status.should == 404
    end
  end # end destroy

  describe "donate" do
    it "should require prior authentication" do
      post :donate, :format => :json, :id => @pa.id
      response.status.should == 401
    end

    it "should work" do
      amount = 10
      cgi = 1
      setup_authenticated_session
      PaymentAccount.any_instance.stub(:donate).with(amount.to_s, cgi.to_s).and_return({})
      post :donate,:format => :json, :id => @pa.id, :payment_account => {:amount => amount, :charity_group_id => cgi}
      response.status.should == 200
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      PaymentAccount.find(id).should be_nil
      post :donate, :format => :json, :id => id
      response.status.should == 404
    end

    it "should render exception" do
      setup_authenticated_session
      PaymentAccount.any_instance.stub(:donate).and_raise(CharityGroupInvalid)
      post :donate,:format => :json, :id => @pa.id, :payment_account => {:amount => 10, :charity_group_id => 1}
      response.status.should == 400
      resp = JSON.parse(response.body)
      resp['message'].should == 'CharityGroupInvalid'
    end
  end # end donate
end
