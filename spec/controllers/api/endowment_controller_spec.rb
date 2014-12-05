require 'spec_helper'

describe Api::EndowmentController do

  describe "index" do
    it "should not require prior authentication" do
      get :index, :format => :json
      response.status.should == 200
      endowment = create(:endowment)
      resp = JSON.parse(response.body)
      charity = resp.select { |char| char['name'] == endowment.name }
      charity.should_not be_nil
    end

    it "should work" do
      get :index, :format => :json
      response.status.should == 200
    end
  end # end index

  describe "create" do
    it "should require prior authentication" do
      post :create, :format => :json, :endowment => {}
      response.status.should == 401
    end

    it "should include errors on failure" do
      setup_authenticated_session
      post :create, :format => :json, :endowment => {}
      response.status.should == 422
      resp = JSON.parse(response.body)
      resp['name'].should_not be_blank
    end

    it "should create endowment on success" do
      charity1 = create(:charity)
      charity2 = create(:charity)
      donor = create(:donor)
      setup_authenticated_session(donor)
      post :create, :format => :json, :endowment => {:name => 'Something', :visibility => 'public', :donor_id => "#{donor.id}", :charities => [{:id => "#{charity1.id}"},{:id => "#{charity2.id}"}] }
      response.should be_success
      resp = JSON.parse(response.body)["endowment"]
      resp['name'].should == 'Something'
    end
  end # end create

  describe "show" do
    it "should not require prior authentication" do
      endowment = create(:endowment_with_charity)
      get :show, :format => :json, :id => endowment.id
      response.should be_success
      resp = JSON.parse(response.body)['endowment']
      resp['name'].should == endowment.name
      resp['id'].should == endowment.id
    end

    it "should work" do # same test as above
      endowment = create(:endowment_with_charity)
      get :show, :format => :json, :id => endowment.id
      response.should be_success
      resp = JSON.parse(response.body)['endowment']
      resp['name'].should == endowment.name
      resp['id'].should == endowment.id
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      Endowment.exists?(id).should be_false
      get :show, :format => :json, :id => id
      JSON.parse(response.body)['message'].should =~ /Called id for nil/
    end
  end # end show

  
  describe "add_charity" do
    it "should create an empty endowment and add a charity to it" do
      donor = create(:donor)
      setup_authenticated_session(donor)
      c = create(:charity)
      endowment = create(:endowment, donor: donor)
      json = { :format => 'json', :id => endowment.id, :charities => [{ :id => c.id }] }
      post :add_charity, json
      new_charity = endowment.charities.find( c.id.to_s )
      new_charity.name.should == c.name
    end 

    it "should not add a charity because the endowment already has donations" do
      setup_authenticated_session
      c = create(:charity)
      endowment = create(:endowment)
      pa = create(:payment_account)
      donation = endowment.donations.build(:gross_amount => 50,
                                    :endowment_id => endowment.id,
                                    :payment_account_id => pa.id)
      donation.save!

      post :add_charity, :format => :json, :id => endowment.id, :charity_id => c.id
      endowment.donations.first.gross_amount.should == donation.gross_amount
      donation.destroy

      endowment.reload

      endowment.charities.exists?(c.id).should be_false
      c.destroy
    end

  end #add_charity

  describe "rename_endowment" do
    it "should rename a endowment" do
      donor = create(:donor)
      setup_authenticated_session(donor)
      endowment = create(:endowment, donor: donor)
      post :rename_endowment, :format => :json, :id => endowment.id, :endowment => {:name => "some new name"}
      endowment.reload
      endowment.name.should == "some new name"
    end

    it "should fail because endowment already has donations" do
      setup_authenticated_session
      endowment = create(:endowment)
      pa = create(:payment_account)
      name = endowment.name
      donation = endowment.donations.build(:gross_amount => 50,
                                    :endowment_id => endowment.id,
                                    :payment_account_id => pa.id)
      donation.save!

      post :rename_endowment, :format => :json, :id => endowment.id, :name => "some new name"
      endowment.reload
      endowment.name.should == name
      donation.destroy
    end


  end

end
