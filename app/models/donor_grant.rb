class DonorGrant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :endowment
  belongs_to :donor

  VALID_STATUS = %w(pending denied sent)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
end