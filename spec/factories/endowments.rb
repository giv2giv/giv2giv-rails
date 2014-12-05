FactoryGirl.define do
  factory :endowment do
    sequence(:name) {|n| "Endowment #{n}"}
    visibility 'public'
    factory :endowment_with_charity do
      after(:create) do |endowment|
        endowment.charities << create(:charity)
      end
    end
  end
end
