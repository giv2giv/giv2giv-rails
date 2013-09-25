class PaymentAccount < ActiveRecord::Base
  require "stripe"

  VALID_PROCESSORS = %w(stripe)
  PLAN_ID = 1

  belongs_to :donor
  has_many :donations

  validates :requires_reauth, :inclusion => { :in => [false] }
  validates :processor, :presence => true,
                        :inclusion => { :in => VALID_PROCESSORS }
  validates :donor, :presence => true
  before_validation :set_requires_reauth, :on => :create
  before_validation :downcase_processor, :on => :create

  class << self
    def new_account(stripeToken, donor_id, options = {})
      check_donor = Donor.find(donor_id)
      customer = Stripe::Customer.create( description: "Giv2Giv Subscription", email: check_donor.email, card: stripeToken)
      payment = PaymentAccount.new(options)
      payment.stripe_cust_id = customer.id
      if payment.save
        message = payment
      else
        message = payment.errors
      end
    end

    def update_account(stripeToken, donor_id, payment_id, options = {})
      check_donor = Donor.find(donor_id)
      customer = Stripe::Customer.retrieve(check_donor.payment_accounts.find(payment_id).stripe_cust_id)
      customer.card = stripeToken
      customer.save
    end
    
    def cancel_subscription(cust_id, amount, donate_id)
      cu = Stripe::Customer.retrieve(cust_id)
      total_quantity = cu.subscription.quantity.to_i

      if total_quantity > amount.to_i
        update_qty = total_quantity - amount.to_i 
        cu.update_subscription(:plan => PLAN_ID, :quantity => update_qty.to_i)
      else
        cu.cancel_subscription
      end

      donation = Donation.find(donate_id)
      
      if donation.destroy
        message = {:message => "Your subscription has been canceled"}.to_json
      end
    end

    def cancel_all_subscription(current_donor)
      begin
        payment_accounts = current_donor.payment_accounts
        payment_accounts.each do |payment_account|
          cu = Stripe::Customer.retrieve(payment_account.stripe_cust_id)
          cu.cancel_subscription
          payment_account.donations.each do |donation|
            donation.destroy
          end
        end
        message = {:message => "Your subscriptions has been canceled"}.to_json
      rescue
        message = {:message => "Failed! No active subscription"}.to_json
      end
    end
  end

  def donate_subscription(amount, charity_group_id, payment_id, email)
    raise PaymentAccountInvalid if !self.valid?
    raise CharityGroupInvalid if !(charity = CharityGroup.find(charity_group_id))

    payment_donor = PaymentAccount.find(payment_id)
    charity_group = CharityGroup.find(charity_group_id)
    charity = charity_group.charities.all.size
    check_donor = Donor.find(payment_donor.donor_id)

    if check_donor
      if charity > 0
        if amount.to_i < charity_group.minimum_donation_amount.to_i
          message = {:message => "Minimum amount for create donation $#{charity_group.minimum_donation_amount}"}.to_json
        else
          customer = Stripe::Customer.retrieve(check_donor.payment_accounts.find(payment_id).stripe_cust_id)
          if customer.subscription.blank?
            customer.update_subscription(:plan => PLAN_ID, :quantity => amount.to_i)
          else
            customer.update_subscription(:plan => PLAN_ID, :quantity => customer.subscription.quantity + amount.to_i)  
          end
          donation = donor.donations.build(:amount => amount,
                                           :charity_group_id => charity_group_id,
                                           :transaction_processor => processor,
                                           :payment_account_id => payment_id,
                                           :transaction_type => "subscription"
                                           )
          donation.save
          donation
        end
      else
        message = {:message => "You need add one or more charity to this group"}.to_json
      end
    else
      message = {:message => "Wrong donor id"}.to_json
    end

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