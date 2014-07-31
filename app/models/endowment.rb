class Endowment < ActiveRecord::Base

  VALID_TYPE = %w(public private)

  has_many :donations, dependent: :destroy
  has_many :grants
  belongs_to :donor
  has_and_belongs_to_many :charities

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :minimum_donation_amount, :presence => true, :format => { :with => /^\d+??(?:\.\d{0,2})?$/ }, :numericality => {:greater_than => 0}
  validates :visibility, :presence => true, :inclusion => { :in => VALID_TYPE }

  extend FriendlyId
  friendly_id :name, use: :slugged

  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  def as_json(options = {})
    super( :include => [:charities => { :only => [:id, :name, :active] }] )
  end

  def add_charity(charities)
    charities.each do |charity|
      self.charities << Charity.find(charity[:id])
    end
  end

  def remove_charity(endowment_id, charity_id)
    endowment = Endowment.find(endowment_id)
    charity = endowment.charities.find(charity_id)
    endowment.charities.delete(charity)
  end

  def share_balance
    BigDecimal("#{self.donations.sum(:shares_added)}") - BigDecimal("#{self.grants.sum(:shares_subtracted)}")
  end

  def last_donation_price
    Share.last.donation_price.floor2(2) rescue 0.0
  end

  def global_balances
    endowment_balance = share_balance * last_donation_price
    monthly_addition = DonorSubscription.where("endowment_id = ? AND canceled_at IS NULL OR canceled_at = ?", self.id, false).sum(:gross_amount) || 0.0
    {
      "endowment_donor_count" => self.donations.count('donor_id', :distinct => true),
      "endowment_donations_count" => self.donations.count('id', :distinct => true),
      "endowment_total_donations" => self.donations.sum(:gross_amount).floor2(2),
      "endowment_monthly_donations" => monthly_addition.floor2(2),
      "endowment_transaction_fees" => self.donations.sum(:transaction_fees).floor2(2),
      "endowment_fees" => self.grants.sum(:giv2giv_fee).floor2(2),
      "endowment_grants" => self.grants.sum(:grant_amount).floor2(2),
      "endowment_balance" => (share_balance * last_donation_price).floor2(2)#,
      #"projected_balance" => project_amount( endowment_balance, monthly_addition, 25, 0.06 )
    }
  end

  def anonymous_donation (accepted_terms, stripeToken, endowment_id, amount, email)
    
      if email.nil
        email = 'anonymous_donor@' + SecureRandom.uuid + '.com'
      end

      anonymous_donor = Donor.new(
          :name => 'Anonymous Donor',
          :email=> email,
          :password => SecureRandom.urlsafe_base64,
          :accepted_terms => accepted_terms
        )

      anonymous_donor.type_donor = "anonymous"

      if accepted_terms==true
        anonymous_donor.accepted_terms = true
        anonymous_donor.accepted_terms_on = DateTime.now      
      end

      anonymous_donor.save!

      payment = PaymentAccount.new_account(stripeToken, anonymous_donor.id, {:donor => anonymous_donor})

      donation = PaymentAccount.one_time_payment(amount, endowment_id, payment.id)

  end



  def project_amount ( principal, monthly_addition, years, return_rate )
    amount_array = []
    total_donations = 0.0
    total_grants = 0.0
    total_fees = 0.0

    month = 1
    while month <= years * 12 do
      month = month + 1
      total_donations += monthly_addition
      principal += monthly_addition
      principal += principal * (return_rate / 12) 
      if month % 4 == 0
        grant_amount = principal * App.giv["giv_grant_amount"]
        total_grants += grant_amount
        fee_amount = principal * App.giv["giv_fee_amount"]
        total_fees += fee_amount
        principal -= grant_amount
        principal -= fee_amount
      end
      if month % 12 == 0
        amount_hash = {
          "date" => Date.today + month.months,
          "total_donations" => total_donations.floor2(2),
          "principal" => principal.floor2(2),
          "total_grants" => total_grants.floor2(2),
          "total_fees" => total_fees.floor2(2)
        }
        amount_array << amount_hash
      end

    end

    amount_array

  end

end
