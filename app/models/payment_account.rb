class PaymentAccount < ActiveRecord::Base
  require "stripe"

  VALID_PROCESSORS = %w(stripe)
  PLAN_ID = '1cent'
  PER_SHARE_DEFAULT = 100000
  SHARE_TOTAL_DEFAULT = 0
  SHARE_PRECISION = App.giv["share_precision"]
  MINIMUM_DONATION = App.giv["minimum_donation_amount"]

  belongs_to :donor
  has_many :donations
  has_many :donor_subscriptions

  validates :processor, :presence => true, :inclusion => { :in => VALID_PROCESSORS }
  validates :donor, :presence => true
  before_validation :downcase_processor, :on => :create

  def downcase_processor
    self.processor = self.processor.downcase if self.processor
    true
  end

  class << self

    def new_account(stripeToken, donor_id, options = {})
      
      check_donor = Donor.find(donor_id)
      
      if !check_donor
        return { :message => "Wrong donor id" }.to_json
      end
      customer = Stripe::Customer.create(description: "giv2giv subscription", email: check_donor.email, card: stripeToken)
      payment = PaymentAccount.new(options)
      payment.stripe_cust_id = customer.id
      if payment.save
        payment
      else
        payment.errors
      end
    end

    def update_account(stripeToken, donor_id, paymentaccount_id, options = {})
      check_donor = Donor.find(donor_id)
      customer = Stripe::Customer.retrieve(check_donor.payment_accounts.find(paymentaccount_id).stripe_cust_id)
      customer.card = stripeToken
      customer.save
    end

    def cancel_subscription(current_donor, subscription_id)
      begin

        subscription = DonorSubscription.where(:id => subscription_id).where(:donor_id => current_donor.id).last
        cust_id = PaymentAccount.find(subscription.payment_account_id).stripe_cust_id
        
        begin
          cu = Stripe::Customer.retrieve(cust_id)
          cu.subscriptions.retrieve(subscription.stripe_subscription_id).delete()
          subscription.canceled_at = DateTime.now
          subscription.save!
          { :message => "Your subscription has been canceled" }.to_json

        rescue Stripe::Error => e
          body = e.json_body
          err = body[:error]
          { :message => "#{err[:message]}" }.to_json
          return 
        end

      rescue
        { :message => "Failed! Subscription or payment account not found" }.to_json
      end

    end

    def cancel_all_subscription(current_donor)
      begin
        payment_accounts = current_donor.payment_accounts
        payment_accounts.each do |payment_account|
          begin

            subscriptions = Stripe::Customer.retrieve(payment_account.stripe_cust_id).subscriptions.all()
            subscriptions.each do |subscription|
              subscription.delete()
            end

          payment_account.donor_subscriptions.destroy_all
          rescue Stripe::CardError => e
            body = e.json_body
            err  = body[:error]
            { :message => "#{err[:message]}" }.to_json
            return false
          end
        end
        { :message => "Your subscriptions has been canceled" }.to_json
      rescue
        { :message => "Failed! No active subscription" }.to_json

      end
    end
  end # end class self

  def one_time_payment(amount, endowment_id, paymentaccount_id)

    raise PaymentAccountInvalid unless self.valid?
    raise EndowmentInvalid unless (endowment = Endowment.find_by_id(endowment_id))

    endowment = Endowment.find_by_id(endowment_id)
    num_of_charity = endowment.charities.count
    current_donor = Donor.find(self.donor_id)

    if amount.to_f < MINIMUM_DONATION
      return { :message => "Minimum donation is $#{MINIMUM_DONATION}" }.to_json
    end

    amount = amount.to_f.round(2)
    amount_cents = (amount * 100).to_i # convert to cents

    if endowment.visibility.eql?("private") && self.donor_id != endowment.donor_id
      return { :message => "Sorry! You cannot make a donation to a private endowment" }.to_json
    end

    if num_of_charity < 1
      return { :message => "No charities in this endowment" }.to_json
    end

    #if amount < endowment.minimum_donation_amount.to_i
      #return { :message => "Minimum amount for create donation $#{endowment.minimum_donation_amount}" }.to_json
    #end

    if !current_donor
      return { :message => "Wrong donor id" }.to_json
    end

    begin
      customer = Stripe::Customer.retrieve(self.stripe_cust_id)

      cust_charge = Stripe::Charge.create(
       :amount => amount_cents,
       :currency => "usd",
       :description => "giv2giv.org donation to #{endowment.name}",
       :customer => self.stripe_cust_id,
      )

      subscription = current_donor.donor_subscriptions.build(
       :donor_id => current_donor.id,
       :payment_account_id => self.id,
       :endowment_id => endowment.id,
       :stripe_subscription_id => cust_charge.id,
       :type_subscription => "single_donation",
       :gross_amount => amount,
       :canceled_at => DateTime.now
       )

    rescue Stripe::CardError => e
        body = e.json_body
        err  = body[:error]
        { :message => "#{err[:message]}" }.to_json
        return false
    end

    if subscription.save
      { :message => "Success" }.to_json
    else
      { :message => "Error" }.to_json
    end # end subscription.save
  end # end one_time_payment

  def donate_subscription(amount, endowment_id, paymentaccount_id)
Rails.logger.debug '1'
    raise PaymentAccountInvalid unless self.valid?
    raise EndowmentInvalid unless Endowment.find_by_id(endowment_id)
Rails.logger.debug '2'
    payment_donor = PaymentAccount.find_by_id(paymentaccount_id)
    endowment = Endowment.find_by_id(endowment_id)
    num_of_charity = endowment.charities.count
    check_donor = Donor.find(payment_donor.donor_id)
Rails.logger.debug '3'
    if amount.to_f < MINIMUM_DONATION
      return { :message => "Minimum donation is $#{MINIMUM_DONATION}" }.to_json
    end
Rails.logger.debug '4'
    amount = amount.to_f.round(2)
    amount_cents = (amount * 100).to_i # convert to cents
Rails.logger.debug '5'

    if endowment.visibility.eql?("private") && payment_donor.donor_id != endowment.donor_id
      return { :message => "Sorry! You cannot make a donation to a private endowment" }.to_json
    end

    if num_of_charity < 1
      return { :message => "No charities in this endowment" }.to_json
    end

    if !check_donor
      return { :message => "Wrong donor id" }.to_json
    end

    begin
      customer = Stripe::Customer.retrieve(check_donor.payment_accounts.find(paymentaccount_id).stripe_cust_id)

      id_subscription = customer.subscriptions.create(:plan => PLAN_ID, :quantity => amount_cents, :prorate => false)

      subscription = donor.donor_subscriptions.build(
       :donor_id => donor.id,
       :payment_account_id => paymentaccount_id,
       :endowment_id => endowment_id,
       :stripe_subscription_id => id_subscription.id,
       :type_subscription => "per-month",
       :gross_amount => amount
       )
    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      { :message => "#{err[:message]}" }.to_json
      return false
    end

    if subscription.save
      { :message => "Success" }.to_json
    else
      { :message => "Error" }.to_json
    end # end subscription.save

  end # end donate_subscription

end  # end class payment_account
