require 'spec_helper'

describe "donors/new" do
  before(:each) do
    assign(:donor, stub_model(Donor,
      :name => "MyString",
      :email => "MyString"
    ).as_new_record)
  end

  it "renders new donor form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", donors_path, "post" do
      assert_select "input#donor_name[name=?]", "donor[name]"
      assert_select "input#donor_email[name=?]", "donor[email]"
    end
  end
end
