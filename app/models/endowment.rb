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

  def add_charity(charity_ids)
    charity_ids = charity_ids.split(",").map { |s| s.to_i }
    charity_ids.each do |charity_id|
      self.charities << Charity.find(charity_id)
    end
  end

  def remove_charity(endowment_id, charity_id)
    endowment = Endowment.find(endowment_id)
    charity = endowment.charities.find(charity_id)
    endowment.charities.delete(charity)
  end

end
