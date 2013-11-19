class CharityGrant < ActiveRecord::Base
  belongs_to :charity

  VALID_STATUS = %w(sent uncollected collected)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
end
