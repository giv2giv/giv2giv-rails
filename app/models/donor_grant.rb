class DonorGrant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :charity_group
  belongs_to :donor

  VALID_STATUS = %w(pending denied sent)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
end