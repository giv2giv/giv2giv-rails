class Charity < ActiveRecord::Base

  has_and_belongs_to_many :endowments
  has_and_belongs_to_many :tags
  has_many :charity_grants, dependent: :destroy
  
  validates :ein, :presence => true, :uniqueness => true
  validates :name, :presence => true

  class << self

    def create_or_update(options = {})
      raise ArgumentError unless options[:ein].present? && options[:name].present?
      charity = Charity.where(:ein => options[:ein]).first_or_create
      charity.update_attributes(options.except(:ein))
      charity
    end

  end # end self

end
