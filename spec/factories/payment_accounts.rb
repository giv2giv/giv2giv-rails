FactoryGirl.define do
  factory :payment_account do
    processor 'stripe'
    association :donor
  end
end