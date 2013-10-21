class PaymentAccount < ActiveRecord::Base
  require "stripe"
  
  VALID_PROCESSORS = %w(stripe)
  PLAN_ID = 1 
  PER_SHARE_DEFAULT = 100000
  SHARE_TOTAL_DEFAULT = 0
  SHARE_PRECISION = App.giv["share_precision"]
  STRIPE_FEES = App.stripe["fees"]
  STRIPE_FEES_CENTS = App.stripe["fees_cents"]

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

  def one_time_payment(amount, charity_group_id, email = nil, stripeToken = nil)
    raise CharityGroupInvalid unless CharityGroup.find(charity_group_id)

    charity_group = CharityGroup.find(charity_group_id)
    num_of_charity = charity_group.charities.count
    check_donor = Donor.find_by_email(email)
    amount = amount.to_i

    if (charity_group.charity_group_visibility.eql?("private")) and (check_donor.id != charity_group.donor_id)
      { :message => "Sorry! You cannot make a donation to a private charity group" }.to_json
    else

      if num_of_charity > 0
        if amount < charity_group.minimum_donation_amount.to_i
          { :message => "Minimum amount for create donation $#{charity_group.minimum_donation_amount}" }.to_json
        else
          random_password = SecureRandom.hex(10)
          random_name = SecureRandom.hex(10)
            
          if check_donor.blank?
            # entry as unregistered donor
            email = random_name + "@" + random_password + ".com"

            customer = Stripe::Customer.create(description: "Giv2Giv Donation", email: email, card: stripeToken)
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
                                        :customer => payment.stripe_cust_id,
                                        :metadata => { :charity_group_id => charity_group_id }
                                       )

                # From https://stripe.com/docs/api?lang=ruby#create_charge
                # stripe returns a charge object if the charge succeeded                 

                # stripe charge.succeeded webhook will do Donation.new(:shares_added => #{math})
                  
                  if !Stripe::Error
                    { :message => "Success" }.to_json
                  else
                    { :message => "Error" }.to_json
                  end # end cust_charge
                else
                  payment.errors
                end # end payment save
              else
                { :message => "Error! Creating payment account" }.to_json    
              end # end donor save

          else
            if check_donor.type_donor.eql?("unregistered")
              cu = Stripe::Customer.retrieve(check_donor.payment_accounts.last.stripe_cust_id)
              cu.card = stripeToken
              cu.save
              cust_charge = Stripe::Charge.create(
                                          :amount => amount * 100,
                                          :currency => "usd",
                                          :description => "giv2giv.org donation to #{CharityGroup.find(charity_group_id).name}",
                                          :customer => check_donor.payment_accounts.last.stripe_cust_id
                                         )

              # From https://stripe.com/docs/api?lang=ruby#create_charge
              # stripe returns a charge object if the charge succeeded                 

              # stripe charge.succeeded webhook will do Donation.new(:shares_added => #{math})

              if !Stripe::Error
                { :message => "Success" }.to_json
              else
                { :message => "Error" }.to_json
              end # end cust_charge
            else

              # do what for registered donor ?
              # stripe.update_subscription()

            end # end check registered email
          end #end check email
        end # end check minimum donation
      else
        { :message => "You need add one or more charity to this group" }.to_json
      end # end check charity
    end # end check visibility

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

      #cancel giv2giv subscription to charity_group
      donor.subscription.find(charity_group_id).destroy

      #NO we NEVER destroy Donation after we receive money! If donation.destroy then we lose :shares_added

      #donation = Donation.find(donate_id)
        #donation
      #if donation.destroy
      if !Stripe::Error
        { :message => "Your subscription has been canceled" }.to_json
      #end
    end

    def cancel_all_subscription(current_donor)
      begin
        payment_accounts = current_donor.payment_accounts
        payment_accounts.each do |payment_account|
          cu = Stripe::Customer.retrieve(payment_account.stripe_cust_id)
          cu.cancel_subscription

        #cancel giv2giv subscription to all charity_groups
        donor.subscription.all.destroy

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
      { :message => "Sorry! You cannot make a donation to a private charity group" }.to_json
    else

      if check_donor
        if num_of_charity > 0
          if amount < charity_group.minimum_donation_amount.to_i
            { :message => "Minimum amount for create donation $#{charity_group.minimum_donation_amount}" }.to_json
          else
            customer = Stripe::Customer.retrieve(check_donor.payment_accounts.find(payment_id).stripe_cust_id)
            if customer.subscription.blank?
              id_subscription = customer.update_subscription(:plan => PLAN_ID, :quantity => amount, :prorate => false)
            else
              id_subscription = customer.update_subscription(:plan => PLAN_ID, :quantity => customer.subscription.quantity + amount, :prorate => false)
            end # end customer subscription

            subscription = donor.donor_subscriptions.build(:donor_id => donor.id,
                                             :payment_account_id => payment_id,
                                             :charity_group_id => charity_group_id,
                                             :stripe_subscription_id => id_subscription.id, # why do we need this? There is only one stripe.subscription for each donor
                                             :amount => amount, # amount donated each month to charity_group_id
                                             :type_donation => "subscription"
                                             )

            if subscription.save
              { :message => "Success" }.to_json
            else
              { :message => "Error" }.to_json
            end # end subscription.save

          end # end check minimum donation
        else
          { :message => "You need to add one or more charity to this group" }.to_json
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
