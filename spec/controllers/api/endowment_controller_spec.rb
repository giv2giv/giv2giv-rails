require 'spec_helper'

describe Api::EndowmentController do

  describe "index" do
    it "should not require prior authentication" do
      get :index, :format => :json
      response.status.should == 200
      cg = create(:endowment)
      resp = JSON.parse(response.body)
      charity = resp.select { |char| char['name'] == cg.name }
      charity.should_not be_nil
    end

    it "should work" do
      setup_authenticated_session
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

    it "should work" do
      setup_authenticated_session
      charity1 = create(:charity)
      charity2 = create(:charity)
      post :create, :format => :json, 
        :name => 'Something',
        :minimum_donation_amount => 50,
        :endowment_visibility => 'public',
        :charity_id => "#{charity1.id},#{charity2.id}"
      response.should be_success
      resp = JSON.parse(response.body)['endowment']
      resp['id'].should_not be_blank
      resp_char = resp['charities'].first
      resp_char['id'].should == charity1.id
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

    it "should work" do
      donor = create(:donor)
      setup_authenticated_session(donor)
      endowment = create(:endowment, donor: donor)
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
      JSON.parse(response.body)['message'].should =~ /Couldn't find/
    end
  end # end show

  describe "add_charity" do
    it "should create an empty endowment and add a charity to it" do
      donor = create(:donor)
      setup_authenticated_session(donor)

      c = create(:charity)
      endowment = create(:endowment, donor: donor)
      post :add_charity, :format => :json, :id => endowment.id, :charity_id => c.id.to_s
      new_charity = endowment.charities.find( c.id )
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

      endowment.reload

      endowment.charities.exists?(c.id).should be_false
      c.destroy
    end

  end #add_charity

  describe "rename_endowment" do
    it "should rename a endowment" do
      donor = create(:donor)
      setup_authenticated_session(donor)
      cg = create(:endowment, donor: donor)
      post :rename_endowment, :format => :json, :id => cg.id, :endowment => {:name => "some new name"}
      cg.reload
      cg.name.should == "some new name"
    end

    it "should fail because endowment already has donations" do
      setup_authenticated_session
      cg = create(:endowment)
      pa = create(:payment_account)
      name = cg.name
      donation = cg.donations.build(:gross_amount => 50,
                                    :endowment_id => cg.id,
                                    :payment_account_id => pa.id)
      donation.save!

      post :rename_endowment, :format => :json, :id => cg.id, :name => "some new name"
      cg.reload
      cg.name.should == name
    end


  end

end
