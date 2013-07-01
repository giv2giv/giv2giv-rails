require 'lib/irs_charity_classification_codes'

class Charity < Neo4j::Rails::Model
  include IRS::CharityClassificationCodes

  property :id
  property :created_at
  property :updated_at
  property :name, :index => :exact
  property :ein, :index => :exact
  property :address
  property :city
  property :state
  property :zip
  property :ntee_code
  property :classification_code
  property :subsection_code
  property :activity_code

  has_n(:charity_groups).from(CharityGroup, :charities)
  has_n(:tags).from(Tag, :charities)

  validates :ein, :presence => true,
                  :uniqueness => true
  validates :name, :presence => true

  class << self
    def create_or_update(options = {})
      raise ArgumentError unless options[:ein].present? && options[:name].present?

      charity = Charity.find_or_initialize_by(:ein => options[:ein])
      charity.attributes = options.except(:ein)
      charity.save
      charity
    end

  end # end self

end
