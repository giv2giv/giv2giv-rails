class Grant < ActiveRecord::Base
	belongs_to :charity
  belongs_to :endowment
  belongs_to :donor

  VALID_STATUS = %w(pending_approval denied pending_acceptance accepted reclaimed failed canceled)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }

end