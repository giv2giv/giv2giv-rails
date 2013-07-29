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
      charity = resp.select { |char| char['name'] == default_charity_1.name }
      charity.should_not be_nil
    end

    it "should work when authenticated" do
      setup_authenticated_session
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      charity = resp.select { |char| char['name'] == default_charity_1.name }
      charity.should_not be_nil
    end
  end # end index

  describe "show" do
    it "should not require prior authentication" do
      get :show, :format => :json, :id => @c1.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @c1.name
      resp['id'].should == @c1.id
      resp['ein'].should == @c1.ein
    end

    it "should work when authenticated" do
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
  end # end show

  describe "search" do
    it "should not require prior authentication" do
      t = Tag.create(:name => 'mee')
      t.charities << default_charity_1
      t.save
      get :search, :format => :json, :search_string => 'mee'
      response.status.should == 200
    end

    it "should work when authenticated" do
      setup_authenticated_session
      t = Tag.create(:name => 'asdf')
      t.charities << default_charity_2
      t.save
      get :search, :format => :json, :search_string => 'asdf'
      response.status.should == 200
    end

    it "should not be found" do
      setup_authenticated_session
      name = 'aaaaaaaaaaaab'
      Tag.find_by_name(name).should be_nil
      get :search, :format => :json, :search_string => name
      response.status.should == 404
    end
  end # end search





end
