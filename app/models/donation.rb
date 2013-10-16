class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :charity_group
  belongs_to :donor
  
  with_options :presence => true do |donation|
    donation.validates :amount
    donation.validates :transaction_processor
  end
end
