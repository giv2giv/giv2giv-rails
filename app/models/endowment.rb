class Endowment < ActiveRecord::Base

  VALID_TYPE = %w(public private)

  has_many :donations, dependent: :destroy
  has_many :donor_grants, dependent: :destroy
  has_many :charity_grants, dependent: :destroy
  belongs_to :donor
  has_and_belongs_to_many :charities

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :minimum_donation_amount, :presence => true, :format => { :with => /^\d+??(?:\.\d{0,2})?$/ }, :numericality => {:greater_than => 0}
  validates :endowment_visibility, :presence => true, :inclusion => { :in => VALID_TYPE }

  class << self
    def new_with_charities(options = {})
      charity_ids = options.delete(:charity_ids) || []
      group = Endowment.new(options)

      group.charities << Charity.find(charity_ids)

      group
    end
  end # end self

  def as_json(options = {})
    super(:include =>[:charities])
  end

  def add_charity(charity_ids)
    charity_ids = charity_ids.split(",").map { |s| s.to_i }
    charity_ids.each do |charity_id|
      self.charities << Charity.find(charity_id)
    end
  end

  def remove_charity(group_id, charity_id)
    group = Endowment.find(group_id)
    charity = group.charities.find(charity_id)
    group.charities.delete(charity)
  end

end
