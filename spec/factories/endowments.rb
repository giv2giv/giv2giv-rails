FactoryGirl.define do
  factory :endowment do
    sequence(:name) {|n| "Endowment #{n}"}
    endowment_visibility 'public'
    minimum_donation_amount 1.00
    factory :endowment_with_charity do
      after(:create) do |endowment|
        endowment.charities << create(:charity)
      end
    end
  end
end