class Etrade < ActiveRecord::Base
  validates :balance, :presence => true

end