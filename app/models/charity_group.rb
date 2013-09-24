class CharityGroup < ActiveRecord::Base
  has_many :donations
  has_and_belongs_to_many :charities

  validates :name, :presence => true,
                   :uniqueness => { :case_sensitive => false }
  validates :minimum_donation_amount, :presence => true, :format => { :with => /^\d+??(?:\.\d{0,2})?$/ }, :numericality => {:greater_than => 0}

  class << self
    def new_with_charities(options = {})
      charity_ids = options.delete(:charity_ids) || []
      group = CharityGroup.new(options)
      charity_ids.each do |cid|
        group.charities << Charity.find!(cid)
      end

      group
    end
  end # end self

  def as_json(options = {})
    super(:include =>[:charities])
  end

  def add_charity(new_charity_id)
    charity = Charity.find(new_charity_id)
    self.charities << charity
    self.charities
  end

  def remove_charity(group_id, charity_id)
    group = CharityGroup.find(group_id)
    charity = group.charities.find(charity_id)
    group.charities.delete(charity)
  end

end