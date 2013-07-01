require 'spec_helper'

describe Tag do
  describe "validations" do
    it "should have a name" do
      t = Tag.new
      t.should_not be_valid
      t.should have(1).error_on(:name)
      t.name = 'Yogurt'
      t.should be_valid
    end
  end

  describe "find_by_name" do
    it "should handle nil name" do
      t = Tag.find_by_name(nil)
      t.should be_nil
    end

    it "should handle empty name" do
      t = Tag.find_by_name('')
      t.should be_nil
    end

    it "should handle name with space" do
      t = Tag.find_by_name('stupid space')
      t.should be_nil
    end

    it "should find by name" do
      name = 'test tag'
      t = Tag.create(:name => name)
      t.should be_valid
      t2 = Tag.find_by_name(name)
      t.should == t2
    end
  end

  describe "relationships" do
    it "should work" do
      t = Tag.create(:name => 'test tag2')
      t.should be_valid
      t.charities << default_charity_1
      t.save
      t.reload
      default_charity_1.reload
      t.charities.first.should == default_charity_1
      default_charity_1.tags.first.should == t
    end
  end

end
