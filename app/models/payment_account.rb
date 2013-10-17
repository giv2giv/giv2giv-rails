class PaymentAccount < ActiveRecord::Base
  require "stripe"
  
  VALID_PROCESSORS = %w(stripe)
  PLAN_ID = 1 
  PER_SHARE_DEFAULT = 100000
  SHARE_TOTAL_DEFAULT = 0

  belongs_to :donor
  has_many :donations

  validates :requires_reauth, :inclusion => { :in => [false] }
  validates :processor, :presence => true, :inclusion => { :in => VALID_PROCESSORS }
  validates :donor, :presence => true
  before_validation :set_requires_reauth, :on => :create
  before_validation :downcase_processor, :on => :create

  class << self
    def new_account(stripeToken, donor_id, options = {})
      check_donor = Donor.find(donor_id)
      customer = Stripe::Customer.create(description: "Giv2Giv Subscription", email: check_donor.email, card: stripeToken)
      payment = PaymentAccount.new(options)
      payment.stripe_cust_id = customer.id
      if payment.save
        payment
      else
        payment.errors
      end
    end

  def one_time_payment(amount, charity_group_id, email, stripeToken)
    raise CharityGroupInvalid unless CharityGroup.find(charity_group_id)

    check_email = Donor.find_by_email(email)

    if check_email.blank?
      customer = Stripe::Customer.create(description: "Giv2Giv Donation", email: email, card: stripeToken)
      # entry as unregistered donor
      random_password = SecureRandom.hex(10)
      random_name = SecureRandom.hex(5)
      donor = Donor.new(
                         :name => random_name,
                         :email => email,
                         :password => random_password,
                         :type_donor => 'unregistered'
                       )

      if donor.save
        # create new payment
        payment = PaymentAccount.new(
                                     :processor => "stripe",
                                     :donor_id => donor.id,
                                     :requires_reauth => 0,
                                     :stripe_cust_id => customer.id
                                    )
        if payment.save
          cust_charge = Stripe::Charge.create(
                                :amount => amount * 100,
                                :currency => "usd",
                                :description => "giv2giv.org donation to #{CharityGroup.find(charity_group_id).name}",
                                :customer => payment.stripe_cust_id
                               )
          check_share_price = Share.last
          if check_share_price.blank?
            per_share = PER_SHARE_DEFAULT
          else
            per_share = check_share_price.donation_price
          end

          buy_shares = (BigDecimal("#{amount}") / BigDecimal("#{per_share}")).round(SHARE_PRECISION)
          donation = Donation.new(
                                 :amount => amount,
                                 :charity_group_id => charity_group_id,
                                 :transaction_processor => payment.processor,
                                 :payment_account_id => payment.id,
                                 :transaction_type => "onetime-payment",
                                 :shares_added => buy_shares,
                                 :donor_id => donor.id
                                 )
          if donation.save
            donation
          else
            donation.errors
          end # end donation save
        else
          payment.errors
        end # end payment save
      else
        { :message => "Error! Creating payment account" }.to_json    
      end # end donor save
    else
      { :message => "Email address is already been taken" }.to_json
    end #end check email
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
      amount = amount.to_i
      if total_quantity > amount
        update_qty = total_quantity - amount 
        cu.update_subscription(:plan => PLAN_ID, :quantity => update_qty)
      else
        cu.cancel_subscription
      end

      donation = Donation.find(donate_id)
        donation
      if donation.destroy
        { :message => "Your subscription has been canceled" }.to_json
      end
    end

    def cancel_all_subscription(current_donor)
      begin
        payment_accounts = current_donor.payment_accounts
        payment_accounts.each do |payment_account|
          cu = Stripe::Customer.retrieve(payment_account.stripe_cust_id)
          cu.cancel_subscription
        end
        { :message => "Your subscriptions has been canceled" }.to_json
      rescue
        { :message => "Failed! No active subscription" }.to_json
      end
    end

  end # end self

  def donate_subscription(amount, charity_group_id, payment_id, email)
    raise PaymentAccountInvalid unless self.valid?
    raise CharityGroupInvalid unless CharityGroup.find(charity_group_id)

    payment_donor = PaymentAccount.find(payment_id)
    charity_group = CharityGroup.find(charity_group_id)
    num_of_charity = charity_group.charities.count
    check_donor = Donor.find(payment_donor.donor_id)
    amount = amount.to_i

    if (charity_group.charity_group_visibility.eql?("private")) and (payment_donor.donor_id != charity_group.donor_id)
      { :message => "Sorry! You cannot make subscription to this charity group" }.to_json
    else

      if check_donor
        if num_of_charity > 0
          if amount < charity_group.minimum_donation_amount.to_i
            { :message => "Minimum amount for create donation $#{charity_group.minimum_donation_amount}" }.to_json
          else
            customer = Stripe::Customer.retrieve(check_donor.payment_accounts.find(payment_id).stripe_cust_id)
            if customer.subscription.blank?
              customer.update_subscription(:plan => PLAN_ID, :quantity => amount)
            else
              customer.update_subscription(:plan => PLAN_ID, :quantity => customer.subscription.quantity + amount)  
            end

            check_share_price = Share.last
            if check_share_price.blank?
              per_share = PER_SHARE_DEFAULT
            else
              per_share = check_share_price.share_price
            end

            # We should only buy shares if there is an immediate charge and we have a transaction_id !
            buy_shares = (BigDecimal("#{amount}") / BigDecimal("#{per_share}")).round(SHARE_PRECISION)
            donation = donor.donations.build(:amount => amount,
                                             :charity_group_id => charity_group_id,
                                             :transaction_processor => processor,
                                             :payment_account_id => payment_id,
                                             :transaction_type => "subscription",
                                             :shares_added => buy_shares,
                                             :donor_id => donor.id
                                             )
            if donation.save
              donation
            else
              { :message => "Error" }.to_json
            end # end donation.save
          end
        else
          { :message => "You need add one or more charity to this group" }.to_json
        end
      else
        { :message => "Wrong donor id" }.to_json
      end
    end #end check type donation

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
