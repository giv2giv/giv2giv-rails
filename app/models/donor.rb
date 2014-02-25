class Donor < ActiveRecord::Base
  has_many :donations
  has_many :payment_accounts, dependent: :destroy
  has_many :donor_grants
  has_many :donor_subscriptions, dependent: :destroy
  has_many :endowments

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :email, :presence => true,
  :format => { :with => EMAIL_REGEX },
  :uniqueness => { :case_sensitive => false }

  with_options :presence => true do |donor|
    donor.validates :name
    donor.validates :password
    donor.validates_inclusion_of :accepted_terms, :in => [true]
    donor.validates :accepted_terms_on
    donor.validates :type_donor
  end

  before_create { generate_token(:auth_token) }

  class << self
    # needed because of the fulltext index
    def find_by_email(email)
      return nil if email.blank?
      self.where(:email => email).last
    end

    def authenticate(email, password)
      user = self.find_by_email(email)
      if user && user.password == password.to_s
        user
      else
        nil
      end
    end
  end # end self

  def send_password_reset
    token = generate_token(:password_reset_token)
    self.expire_password_reset = Time.zone.now
    save!
    DonorMailer.forgot_password(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while Donor.exists?(column => self[column])
  end

  def as_json(options = {})
    # don't show password in response
    super(:except => [:password])
  end

  def my_balances(endowment_id)

    last_donation_price = Share.last.donation_price rescue 0.0

    is_subscribed = false

    begin
      my_subscription_row = self.donor_subscriptions.where("endowment_id = ?", endowment_id).where("canceled_at IS NULL OR canceled_at = ?", false).last
      is_subscribed = true
      my_subscription_id = my_subscription_row.id
      my_subscription_amount = my_subscription_row.gross_amount
      my_subscription_type = my_subscription_row.type_subscription
      my_subscription_canceled_at = my_subscription_row.canceled_at
    rescue
      is_subscribed = false
    end

    my_donations = self.donations.where("endowment_id = ?", endowment_id)
    my_grants = self.donor_grants.where("endowment_id = ?", endowment_id)

    my_donations_count = my_donations.count('id', :distinct => true)
    my_donations_amount = my_donations.sum(:gross_amount)
    my_donations_shares = my_donations.sum(:shares_added)

    my_grants_amount = my_grants.sum(:gross_amount)
    my_grants_shares = my_grants.sum(:shares_subtracted)

    my_balance_pre_investment = my_donations_amount - my_grants_amount
    my_endowment_share_balance = my_donations_shares - my_grants_shares

    my_endowment_balance = (my_endowment_share_balance * last_donation_price * 10).ceil / 10.0
    
    my_investment_gainloss = (my_endowment_balance - my_balance_pre_investment * 10).ceil / 10.0

    if defined?(:my_donations_count) && my_donations_count > 0
      my_investment_gainloss_percentage = (my_investment_gainloss / my_donations_amount * 100).round(3)
    else
      my_investment_gainloss_percentage = 0.0
    end

    {
      "is_subscribed" => is_subscribed,
      "my_subscription_id" => my_subscription_id || "",
      "my_subscription_amount" => my_subscription_amount.to_f || 0.0,
      "my_subscription_type" => my_subscription_type || "",
      "my_subscription_canceled_at" => my_subscription_canceled_at || "",

      "my_donations_count" => my_donations_count || 0,
      #"my_donations_shares" => my_donations_shares, # We should not expose shares to users -- too confusing
      "my_donations_amount" => my_donations_amount.to_f || 0,
      #"my_grants_shares" => my_grants_shares,
      "my_grants_amount" => my_grants_amount.to_f || 0,

      "my_balance_pre_investment" => my_balance_pre_investment.to_f || 0,
      #"my_endowment_share_balance" => my_endowment_share_balance,

      "my_investment_gainloss" => my_investment_gainloss.to_f || 0,
      "my_investment_gainloss_percentage" => my_investment_gainloss_percentage || 0,
      "my_endowment_balance" => my_endowment_balance.to_f || 0
    }
  end
  
end
