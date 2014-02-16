class Endowment < ActiveRecord::Base

  VALID_TYPE = %w(public private)

  has_many :donations, dependent: :destroy
  has_many :donor_grants, dependent: :destroy
  belongs_to :donor
  has_and_belongs_to_many :charities

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :minimum_donation_amount, :presence => true, :format => { :with => /^\d+??(?:\.\d{0,2})?$/ }, :numericality => {:greater_than => 0}
  validates :visibility, :presence => true, :inclusion => { :in => VALID_TYPE }

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

  def global_balances()
    last_donation_price = Share.last.donation_price rescue 0.0
    share_balance = BigDecimal("#{self.donations.sum(:shares_added)}") - BigDecimal("#{self.donor_grants.sum(:shares_subtracted)}")

    global_balances = {
      "endowment_donor_count" => self.donations.count('donor_id', :distinct => true),
      "endowment_donations_count" => self.donations.count('id', :distinct => true),
      "endowment_donations" => (self.donations.sum(:gross_amount) * 10).ceil / 10.0,
      "endowment_transaction_fees" => (self.donations.sum(:transaction_fees) * 10).ceil / 10.0,
      "endowment_fees" => (self.donor_grants.sum(:giv2giv_fee) * 10).ceil / 10.0,
      "endowment_grants" => (self.donor_grants.sum(:gross_amount) * 10).ceil / 10.0,
      #"endowment_share_balance" => ((self.donations.sum(:shares_added) - endowment.donor_grants.sum(:shares_subtracted)) * 10).ceil / 10.0,
      "endowment_balance" => (share_balance * last_donation_price * 10).ceil / 10.0
    }
  end


end
