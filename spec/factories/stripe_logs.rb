# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :stripe_log do
    type ""
    event "MyText"
  end
end
