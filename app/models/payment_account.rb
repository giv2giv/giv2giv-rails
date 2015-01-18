class PaymentAccount < ActiveRecord::Base
  require "stripe"

  VALID_PROCESSORS = %w(stripe knox)
  PLAN_ID = '1cent'
  PER_SHARE_DEFAULT = 100000
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


  def stripe_charge(type, amount, endowment_id)

    raise PaymentAccountInvalid unless self.valid?
    raise EndowmentInvalid unless Endowment.find_by_id(endowment_id)

    endowment = Endowment.find_by_id(endowment_id)
    num_of_charity = endowment.charities.count
    current_donor = Donor.find(self.donor_id)


    if amount.to_f < MINIMUM_DONATION
      return { :message => "Minimum donation is $#{MINIMUM_DONATION}" }.to_json
    end

    amount = amount.to_f.round(2)
    amount_cents = (amount * 100).to_i # convert to cents

    if endowment.visibility.eql?("private") && current_donor.donor_id != endowment.donor_id
      return { :message => "Sorry! You cannot make a donation to a private endowment" }.to_json
    end

    if num_of_charity < 1
      return { :message => "No charities in this endowment" }.to_json
    end

    if !current_donor
      return { :message => "Wrong donor id" }.to_json
    end

    begin
      if (type=='single_donation')
        cust_charge = Stripe::Charge.create(
          :amount => amount_cents,
          :currency => "usd",
          :description => "giv2giv.org donation to #{endowment.name}",
          :customer => self.stripe_cust_id,
        )
        canceled_at = DateTime.now
      elsif (type=='per-month')
        customer = Stripe::Customer.retrieve(self.stripe_cust_id)
        subscription = customer.subscriptions.create(:plan => PLAN_ID, :quantity => amount_cents, :prorate => false)
      end

      stripe_charge = cust_charge || subscription

      subscription = current_donor.donor_subscriptions.build(
       :donor_id => current_donor.id,
       :payment_account_id => self.id,
       :endowment_id => endowment.id,
       :stripe_subscription_id => stripe_charge.id,
       :type_subscription => type,
       :canceled_at => canceled_at,
       :gross_amount => amount
       )

      if subscription.save
        DonorMailer.new_subscription(current_donor, endowment.name, type, amount).deliver
        { :message => "Success" }.to_json
      else
        { :message => "Error" }.to_json
      end # end subscription.save

    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      { :message => "#{err[:message]}" }.to_json
      return false
    end
  end # end stripe_charge



  class << self

    def new_stripe_account(stripeToken, donor_id, options = {})
      
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

    def new_knox_account(donor_id, options = {})
      
      check_donor = Donor.find(donor_id)
      
      if !check_donor
        return { :message => "Wrong donor id" }.to_json
      end

      payment = PaymentAccount.new(options)
      if payment.save
        payment
      else
        payment.errors
      end
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
  end

end  # end class payment_account
