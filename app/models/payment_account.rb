class PaymentAccount < ActiveRecord::Base
  require "stripe"

  VALID_PROCESSORS = %w(stripe)

  belongs_to :donor
  has_many :donations

  validates :requires_reauth, :inclusion => { :in => [false] }
  validates :processor, :presence => true,
                        :inclusion => { :in => VALID_PROCESSORS }
  validates :donor, :presence => true
  before_validation :set_requires_reauth, :on => :create
  before_validation :downcase_processor, :on => :create

  class << self
    def new_payment(options = {})
      get_token = Stripe::Token.create(
          :card => {
          :number => options["number"],
          :exp_month => options["exp_month"].to_i,
          :exp_year => options["exp_year"].to_i,
          :cvc => options["cvc"]
        },
      )
      get_token
    end
  end

  def donate(amount, charity_group_id, payment_id)
    # FIX ME :(
    raise PaymentAccountInvalid if !self.valid?
    raise CharityGroupInvalid if !(charity = CharityGroup.find(charity_group_id))
    raise AmountInvalid if amount.blank? || amount < 0
    
    donation = donor.donations.build(:amount => amount,
                                     :charity_group_id => charity.id,
                                     :transaction_processor => processor,
                                     :transaction_id => transaction_id,
                                     :payment_account_id => payment_id
                                     )
    donation.save
    donation
  end

private

  def set_requires_reauth
    self.requires_reauth = false if !self.requires_reauth
    true
  end

  def downcase_processor
    self.processor = self.processor.downcase if self.processor
    true
  end
end
