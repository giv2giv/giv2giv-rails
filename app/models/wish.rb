class Wish < ActiveRecord::Base
  validates :wish_text, :presence => true
  validates :page, :presence => true

  attr_accessible :page, :wish_text

end
