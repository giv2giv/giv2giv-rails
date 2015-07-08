class TransitFund < ActiveRecord::Base
  VALID_SOURCES = %w(dwolla stripe etrade)
  validates :source, :presence => true, :inclusion => { :in => VALID_SOURCES }
  VALID_DESTINATIONS = %w(dwolla stripe etrade)
  validates :destination, :presence => true, :inclusion => { :in => VALID_DESTINATIONS }
  VALID_STATUS = %w( processed pending cancelled failed reclaimed )
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
end
