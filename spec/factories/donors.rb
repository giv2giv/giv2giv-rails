FactoryGirl.define do
  factory :donor do
    sequence(:email) {|n| "asdf#{n}@ltc.com"}
    name 'KM'
    password 'dreams'
    type_donor 'registered'

    factory :donor_with_donation do
      after(:create) do |donor|
        endowment = create(:endowment)
        payment_account = create(:payment_account, donor_id: donor.id)
        donation = Donation.create(gross_amount: 5, endowment: endowment, payment_account: payment_account, donor_id: donor.id)
      end
    end
  end
end
