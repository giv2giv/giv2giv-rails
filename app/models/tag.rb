=begin
class Tag < ActiveRecord::Base
  property :name, :index => :fulltext

  property :id
  property :created_at
  property :updated_at

  has_n(:charities).to(Charity)

  validates :name, :presence => true,
                   :uniqueness => { :case_sensitive => false }

  class << self
    def find_by_name(name)
      return nil if name.blank?
      # bug in neo4j.rb. search string with spaces must be in double qoutes
      self.find("name: \"#{name}\"", :type => :fulltext)
    end

    # find_or_create_by doesnt use fulltext index so made this helper
    def find_or_create_by_name(name)
      return nil if name.blank?
      tag = self.find_by_name(name)
      tag ? tag : Tag.create(:name => name)
    end
  end # end self

end
=end
