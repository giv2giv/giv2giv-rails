require 'dwolla'

class PaymentAccount < ActiveRecord::Base
  VALID_PROCESSORS = %w(dwolla)

  property :id
  property :created_at
  property :updated_at

  property :processor # dwolla, paypal, etc
  property :token # do other payment processors use token?
  property :pin # dwolla requires us to know the donor's pin
  property :requires_reauth # should be false unless a payment fails

  has_one(:donor).from(Donor, :payment_accounts)

  validates :requires_reauth, :inclusion => { :in => [false] }
  validates :processor, :presence => true,
                        :inclusion => { :in => VALID_PROCESSORS }
  validates :token, :presence => true
  validates :donor, :presence => true
  before_validation :set_requires_reauth, :on => :create
  before_validation :downcase_processor, :on => :create

  # for one time donation
  def donate(amount, charity_group_id)
    raise PaymentAccountInvalid if !self.valid?
    raise CharityGroupInvalid if !(charity = CharityGroup.find(charity_group_id))
    raise AmountInvalid if amount.blank? || amount < 0

    Dwolla::token = token
    transaction_id = Dwolla::Transactions.send({:destinationId => App.dwolla['account_id'],
                                                :amount => amount.to_f,
                                                :pin => pin})

    # amount = amount after processing fee(s)
    donation = donor.donations.build(:amount => amount,
                                     :charity_group_id => charity.id,
                                     :transaction_id => transaction_id,
                                     :transaction_processor => processor)
    donation.save(false)
    donation
  end
private

  def set_requires_reauth
    # just being nice for create
    self.requires_reauth = false if !self.requires_reauth
    true
  end

  def downcase_processor
    # just being nice for create
    self.processor = self.processor.downcase if self.processor
    true
  end
end
