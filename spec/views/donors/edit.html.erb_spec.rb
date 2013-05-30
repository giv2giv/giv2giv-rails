require 'spec_helper'

describe "donors/edit" do
  before(:each) do
    @donor = assign(:donor, stub_model(Donor,
      :name => "MyString",
      :email => "MyString"
    ))
  end

  it "renders the edit donor form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", donor_path(@donor), "post" do
      assert_select "input#donor_name[name=?]", "donor[name]"
      assert_select "input#donor_email[name=?]", "donor[email]"
    end
  end
end
