class Charity < ActiveRecord::Base

  has_and_belongs_to_many :charity_groups
  has_and_belongs_to_many :tags


  validates :ein, :presence => true,
                  :uniqueness => true
  validates :name, :presence => true

  class << self

    def create_or_update(options = {})
      raise ArgumentError unless options[:ein].present? && options[:name].present?

      charity = Charity.first_or_initialize(:ein => options[:ein])
      charity.attributes = options.except(:ein)
      charity.save
      charity
    end


  end # end self

end
