class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :charity_group

  validates :amount, :presence => true
  validates :transaction_id, :presence => true
  validates :transaction_processor, :presence => true
end
