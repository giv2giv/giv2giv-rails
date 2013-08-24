class Charity < ActiveRecord::Base

  has_and_belongs_to_many :charity_groups
#  has_n(:tags).from(Tag, :charities)


  validates :ein, :presence => true,
                  :uniqueness => true
  validates :name, :presence => true

  class << self
    def find_by_name(name)
      return nil if name.blank?
      # bug in neo4j.rb. search string with spaces must be in double qoutes
      self.find("name: \"#{name}\"", :type => :fulltext)
    end

    def create_or_update(options = {})
      raise ArgumentError unless options[:ein].present? && options[:name].present?

      charity = Charity.find_or_initialize_by(:ein => options[:ein])
      charity.attributes = options.except(:ein)
      charity.save
      charity
    end

  end # end self

end
