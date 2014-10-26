class Wish < ActiveRecord::Base
  validates :wish_text, :presence => true
  validates :page, :presence => true

end
