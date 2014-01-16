require 'spec_helper'

describe Api::PaymentAccountsController do

  before(:each) do
    @pa = create(:payment_account)
    @donor = @pa.donor    
  end

  describe "index" do
    it "should require prior authentication" do
      get :index, :format => :json
      response.status.should == 401
    end

    # TODO: mock out the stripe api to isolate the controller test
    pending "should work" do
      setup_authenticated_session(@donor)
      get :index, :format => :json
      resp = JSON.parse(response.body)
      resp.class.should == Hash
      resp = resp.first["payment_account"]
      resp['id'].should == @pa.id
      resp['processor'].should == @pa.processor
    end
  end # end index

  describe "create" do
    it "should require prior authentication" do
      post :create, :format => :json
      response.status.should == 401
    end

    it "should include errors on failure" do
      setup_authenticated_session(@donor)
      post :create, :format => :json, :payment_account => {}
      resp = JSON.parse(response.body)
      resp['message'].should_not be_blank
    end

    # TODO: mock out the stripe api to isolate the controller test
    pending "should work" do
      setup_authenticated_session(@donor)
      post :create, :format => :json, :stripeToken => "abcd", :processor => 'stripe'
      binding.pry
      response.should be_success
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
      setup_authenticated_session(@donor)
      put :update, :format => :json, :id => @pa.id, :payment_account => {:processor => ''}
      resp = JSON.parse(response.body)
      resp['message'].should_not be_blank
    end

    # TODO: stub out stripe updating to test this action
    pending "should work" do
      setup_authenticated_session(@donor)
      put :update, :format => :json, :id => @pa.id, :processor => 'stripe', :stripeToken => 'abcd'
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['id'].should_not be_blank
      resp['token'].should == params[:token]
    end

    it "should not be found" do
      setup_authenticated_session(@donor)
      id = 12354
      PaymentAccount.exists?(id).should be_false
      put :update, :format => :json, :id => id, :processor => 'stripe', :stripeToken => 'abcd'
      JSON.parse(response.body)['message'].should =~ /Couldn't find PaymentAccount/
    end
  end # end update

  describe "show" do
    it "should require prior authentication" do
      get :show, :format => :json, :id => @pa.id
      response.status.should == 401
    end

    it "should work" do
      setup_authenticated_session(@donor)
      get :show, :format => :json, :id => @pa.id
      resp = JSON.parse(response.body)["payment_account"]
      resp['id'].should == @pa.id
      resp['processor'].should == @pa.processor
    end

    it "should not be found" do
      setup_authenticated_session(@donor)
      id = 12354
      PaymentAccount.exists?(id).should be_false
      get :show, :format => :json, :id => id
      JSON.parse(response.body)['message'].should_not be_blank
    end
  end # end show

  describe "destroy" do
    it "should require prior authentication" do
      delete :destroy, :format => :json, :id => @pa.id
      response.status.should == 401
    end

    it "should work" do
      setup_authenticated_session(@donor)
      PaymentAccount.any_instance.should_receive(:destroy)
      delete :destroy, :format => :json, :id => @pa.id
    end

    pending "should not be found" do
      setup_authenticated_session(@donor)
      id = 12354
      PaymentAccount.exists?(id).should be_false
      delete :destroy, :format => :json, :id => id
      response.status.should == 404
    end
  end # end destroy

  pending "one_time_payment" do

    # currently failing
    it "should require prior authentication" do
      endowment = create(:endowment_with_charity)
      post :one_time_payment, :format => :json, :id => @pa.id, :endowment_id => endowment.id, :gross_amount => 5
      binding.pry
      response.status.should == 401
    end

    it "should work" do
      amount = 10
      endowment_id = 1
      setup_authenticated_session(@donor)
      PaymentAccount.any_instance.stub(:donate).with(amount.to_s, endowment_id.to_s).and_return({})
      post :one_time_payment,:format => :json, :id => @pa.id, :payment_account => {:gross_amount => amount, :endowment_id => endowment_id}
      response.status.should == 200
    end

    it "should not be found" do
      setup_authenticated_session(@donor)
      id = 12354
      PaymentAccount.exists?(id).should be_false
      post :one_time_payment, :format => :json, :id => id
      response.status.should == 404
    end

    it "should render exception" do
      setup_authenticated_session(@donor)
      PaymentAccount.any_instance.stub(:donate).and_raise(EndowmentInvalid)
      post :one_time_payment, :format => :json, :id => @pa.id, :payment_account => {:gross_amount => 10, :endowment_id => 1}
      response.status.should == 400
      resp = JSON.parse(response.body)
      resp['message'].should == 'EndowmentInvalid'
    end
  end # end donate
end
