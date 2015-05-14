class Endowment < ActiveRecord::Base

  VALID_TYPE = %w(public private)

  has_many :donations
  has_many :grants
  belongs_to :donor
  has_and_belongs_to_many :charities

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :visibility, :presence => true, :inclusion => { :in => VALID_TYPE }

  extend FriendlyId
  friendly_id :name, use: :slugged

  searchkick word_start: [:name], callbacks: false#, callbacks: :async

  def search_data
    {
      name: name
    }
  end

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

  def first_donation_date
    self.donations.order("created_at ASC").first.created_at.to_date rescue Date.today
  end

  def load_balance
    @all_donations = self.donations.all
    @all_grants = self.grants.where('(status = ? OR status = ?)', 'accepted', 'pending_acceptance')
  end

  def balance_on(date)
    dt = DateTime.parse(date.to_s)
    dt = dt + 11.hours + 59.minutes + 59.seconds
    shares_added = @all_donations.where('created_at <= ?', dt).sum(:shares_added)
    shares_subtracted = @all_grants.where('created_at <= ?', dt).sum(:shares_subtracted)
    share_price = Share.where('created_at <= ?', dt).order("created_at DESC").first
    #All three type BigDecimal
    balance = (shares_added - shares_subtracted) * share_price.donation_price rescue 0.0
    balance.floor2(2)
  end

  def global_balances

    load_balance
    balance_history = (first_donation_date..Date.today).select {|d| (d.day % 7) == 0 || d==Date.today}.map { |date| {"date"=>date,"balance"=>self.balance_on(date)} }

    endowment_balance = share_balance * last_donation_price

    monthly_addition = DonorSubscription.where("endowment_id = ? AND canceled_at IS NULL OR canceled_at = ?", self.id, false).sum(:gross_amount) || 0.0
    {
      "endowment_donor_count" => self.donations.select(:donor_id).distinct.count,
      "endowment_donations_count" => self.donations.select(:id).distinct.count,
      "endowment_total_donations" => self.donations.sum(:gross_amount).floor2(2),
      "endowment_monthly_donations" => monthly_addition.floor2(2),
      "endowment_transaction_fees" => self.donations.sum(:transaction_fee).floor2(2),
      "endowment_fees" => self.grants.sum(:giv2giv_fee).floor2(2),
      "endowment_grants" => self.grants.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').sum(:grant_amount).floor2(2),
      "endowment_balance_history" => balance_history,
      "endowment_balance" => (share_balance * last_donation_price).floor2(2),
      "projected_balance" => CalculationShare::Calculation.project_amount( {:principal=>endowment_balance.floor(2),:monthly_addition=>monthly_addition.floor2(2)} )
    }
  end

    def anonymous_donation (accepted_terms, stripeToken, endowment_id, amount, email)
      
        if email.blank?
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

        donation = PaymentAccount.stripe_charge('single_donation',amount, endowment_id, payment.id)

    end

end
