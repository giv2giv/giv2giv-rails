class TransitFund < ActiveRecord::Base
  VALID_SOURCES = %w(dwolla stripe etrade)
  validates :source, :presence => true, :inclusion => { :in => VALID_SOURCES }
  VALID_DESTINATIONS = %w(dwolla stripe etrade)
  validates :destination, :presence => true, :inclusion => { :in => VALID_DESTINATIONS }
end
