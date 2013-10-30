require 'spec_helper'

describe Api::EndowmentController do

  before(:each) do
   @cg = default_endowment
  end

  describe "index" do
    it "should not require prior authentication" do
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      charity = resp.select { |char| char['name'] == default_endowment.name }
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
      resp['charities'].should_not be_blank
    end

    it "should work" do
      setup_authenticated_session
      post :create, :format => :json, :endowment => { :name => 'Something', :charity_ids => [default_charity_1.id] }
      response.status.should == 201
      resp = JSON.parse(response.body)
      resp['id'].should_not be_blank
      resp_char = resp['charities'].first
      resp_char['id'].should == default_charity_1.id
      resp_char['ein'].should == default_charity_1.ein
    end
  end # end create

  describe "show" do
    it "should not require prior authentication" do
      get :show, :format => :json, :id => @cg.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @cg.name
      resp['id'].should == @cg.id
    end

    it "should work" do
      setup_authenticated_session
      get :show, :format => :json,:id => @cg.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @cg.name
      resp['id'].should == @cg.id
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      Endowment.find(id).should be_nil
      get :show, :format => :json, :id => id
      response.status.should == 404
    end
  end # end show

  describe "add_charity" do
    it "should create an empty endowment and add a charity to it" do
      setup_authenticated_session

      c = Charity.first
      post :add_charity, :format => :json, :id => @cg.id, :charity_id => c.id
      new_charity = @cg.charities.find( c.id )
      new_charity.name.should == c.name
    end

    it "should not add a charity because the endowment already has donations" do
      setup_authenticated_session
      c = Charity.new(:name => "test charity", :ein =>"8383838383838")
      c.save
      c.reload
=begin      puts c.name
      puts c.id
      puts "\n\n\n\n\nCHARITY ATTRIBUTES  OUTPUT NEXT"
      puts c.attributes
=end
      donation = @cg.donations.build(:amount => 50,
                                     :endowment_id => @cg.id)
      donation.save(false)

      post :add_charity, :format => :json, :id => @cg.id, :charity_id => c.id
      @cg.donations.first.amount.should == donation.amount

      @cg.reload

      @cg.charities.find( c.id ).should be_nil
      puts "DESTRYOING C HOPEFULLY"
      c.destroy
#      c.reload
#      expect{ puts c.attributes }.to raise_error

    end

  end #add_charity

  describe "rename_endowment" do
    it "should rename a endowment" do
      setup_authenticated_session
      post :rename_endowment, :format => :json, :id => @cg.id, :new_name => "some new name"
      @cg.reload
      @cg.name.should == "some new name"
    end

    it "should fail because endowment already has donations" do
      setup_authenticated_session

      donation = @cg.donations.build(:amount => 50,
                                     :endowment_id => @cg.id)
      donation.save(false)

      post :rename_endowment, :format => :json, :id => @cg.id, :new_name => "some new name"
      @cg.reload
      @cg.name.should == "Kendal"

    end


  end















end
