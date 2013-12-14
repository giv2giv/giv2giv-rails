require 'spec_helper'

describe Api::CharityController do

  describe "index" do
    it "should not require prior authentication" do
      c = create(:charity)
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      charity = resp.select { |char| char['name'] == c.name }
      charity.should_not be_nil
    end

    it "should work when authenticated" do
      setup_authenticated_session
      c = create(:charity)
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      charity = resp.select { |char| char['name'] == c.name }
      charity.should_not be_nil
    end
  end # end index

  describe "show" do
    it "should not require prior authentication" do
      c = create(:charity)
      get :show, :format => :json, :id => c.id
      response.status.should == 200
      resp = JSON.parse(response.body)['charity']
      resp['name'].should == c.name
      resp['id'].should == c.id
      resp['ein'].should == c.ein
    end

    it "should work when authenticated" do
      setup_authenticated_session
      c = create(:charity)
      get :show, :format => :json, :id => c.id
      response.status.should == 200
      resp = JSON.parse(response.body)['charity']
      resp['name'].should == c.name
      resp['id'].should == c.id
      resp['ein'].should == c.ein
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      Charity.exists?(id).should be_false
      get :show, :format => :json, :id => id
      resp = JSON.parse(response.body)
      resp['message'].should =~ /Couldn't find Charity/
    end
  end # end show

  describe "search" do
    it "should not require prior authentication" do
      t = Tag.create(:name => 'mee')
      t.charities << create(:charity)
      t.save
      get :index, :format => :json, :query => 'mee'
      response.status.should == 200
    end

    it "should work when authenticated" do
      setup_authenticated_session
      t = Tag.create(:name => 'asdf')
      t.charities << create(:charity)
      t.save
      get :index, :format => :json, :query => 'asdf'
      response.status.should == 200
    end

    it "should not be found" do
      setup_authenticated_session
      name = 'aaaaaaaaaaaab'
      Tag.find_by_name(name).should be_nil
      get :index, :format => :json, :query => name
      JSON.parse(response.body)['message'].should == 'Not found'
    end
  end # end search

end
