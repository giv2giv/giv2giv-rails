class Tag < ActiveRecord::Base

  has_and_belongs_to_many :charities

  validates :name, :presence => true,
                   :uniqueness => { :case_sensitive => false }

  class << self

    # find_or_create_by doesn't use fulltext index so made this helper
    def find_or_create_by_name(name)
      return nil if name.blank?
      tag = self.find_by_name(name)
      tag ? tag : Tag.create(:name => name)
    end
  end # end self

end
