# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :wish do
    donor_id 1
    page "MyText"
    wish "MyText"
  end
end
