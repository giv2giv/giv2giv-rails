class Charity < ActiveRecord::Base

  has_and_belongs_to_many :endowments
  has_and_belongs_to_many :tags
  has_many :grants
  geocoded_by :full_street_address
  #after_validation :geocode          # auto-fetch coordinates

  #geocode on save if address changed
  after_validation :geocode, if: ->(charity){ charity.address.present? and charity.address_changed? }

  #geocode on load if charity not yet geocoded
  after_find :geocode, if: ->(charity){ charity.address.present? and charity.latitude.nil? }
  #force save of new latitude/longitude
  after_initialize do |charity|
    if charity.latitude_changed?
      charity.save!
    end
  end

  validates :ein, :presence => true, :uniqueness => true
  validates :name, :presence => true
  
  extend FriendlyId
  friendly_id :name, use: :slugged

  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  class << self

    def create_or_update(options = {})
      raise ArgumentError unless options[:ein].present? && options[:name].present?
      charity = Charity.where(:ein => options[:ein]).first_or_create
      charity.update_attributes(options.except(:ein))
      charity
    end

  end # end self

  def full_street_address
    [self.address,self.city,self.state,self.zip].join(' ').squeeze(' ')
  end

end
