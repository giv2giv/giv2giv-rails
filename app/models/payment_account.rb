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

  def donate_subscription(plan, amount, charity_group_id, payment_id, email, token)
    raise PaymentAccountInvalid if !self.valid?
    raise CharityGroupInvalid if !(charity = CharityGroup.find(charity_group_id))
    raise PlanInvalid if plan.blank?

    charity_group = CharityGroup.find(charity_group_id)
    charity = charity_group.charities.all.size
    check_donor = Donor.find(charity_group.donor_id)

    if check_donor
      if charity > 0
        if amount.to_i < charity_group.minimum_donation_amount.to_i
          message = {:message => "Minimum amount for create donation $#{charity_group.minimum_donation_amount}"}.to_json
        else
          if check_donor.stripe_cust_id.blank?
            customer = Stripe::Customer.create(description: email, plan: plan, card: token, quantity: amount)
            check_donor.update_attributes(:stripe_cust_id => "#{customer.id}")
          else
            customer = Stripe::Customer.retrieve(check_donor.stripe_cust_id)
            customer.update_subscription(:plan => plan, :quantity => customer.subscription.quantity + amount.to_i)
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